const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { MailService } = require("./services/mail_service");

// Firebase Admin SDK の初期化
initializeApp();
const db = getFirestore();

// お店の通知用メールアドレス
const SHOP_EMAIL = "comehiro.2012@gmail.com";

// 💡 曜日を日本語に変換するための共通配列
const weekDays = ['日', '月', '火', '水', '木', '金', '土'];

const CLOSED_WEEKDAYS = new Set([1, 2]); // JavaScript: 日=0、月=1、火=2
const CUTOFF_HOUR = 15;
const BOOKING_WINDOW_DAYS = 30;
const HOLIDAYS = [
  { start: [2026, 8, 10], end: [2026, 8, 14] },
];

// メール本文に予約者が入力した文字列を埋め込む前に必ずエスケープします。
// HTML をそのまま入れると、メールの表示崩れや意図しないリンクの原因になります。
function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  }[char]));
}

function jstParts(date = new Date()) {
  const jst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  return {
    year: jst.getUTCFullYear(), month: jst.getUTCMonth() + 1,
    day: jst.getUTCDate(), hour: jst.getUTCHours(),
  };
}

function jstDayNumber(year, month, day) {
  return Date.UTC(year, month - 1, day) / 86400000;
}

function isHoliday(year, month, day) {
  const target = jstDayNumber(year, month, day);
  return HOLIDAYS.some(({ start, end }) =>
    target >= jstDayNumber(...start) && target <= jstDayNumber(...end));
}

function validationErrorForPickup(year, month, day, now = new Date()) {
  const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
  if (CLOSED_WEEKDAYS.has(weekday)) return '月曜・火曜は定休日のため予約できません。';
  if (isHoliday(year, month, day)) return 'この日は休業日のため予約できません。';

  const current = jstParts(now);
  const todayNumber = jstDayNumber(current.year, current.month, current.day);
  const targetNumber = jstDayNumber(year, month, day);
  const minOffset = current.hour >= CUTOFF_HOUR ? 2 : 1;
  if (targetNumber < todayNumber + minOffset) return '予約は前日15時までにお願いします。';
  if (targetNumber > todayNumber + BOOKING_WINDOW_DAYS) return '予約できるのは30日先までです。';
  return null;
}

/**
 * 予約登録の唯一の入口です。クライアントが古いWeb版でも、ここで定休日・締切を必ず再検証します。
 */
exports.createReservation = onCall({ region: 'asia-northeast1' }, async (request) => {
  const data = request.data || {};
  const year = Number(data.pickupYear);
  const month = Number(data.pickupMonth);
  const day = Number(data.pickupDay);
  const hour = Number(data.pickupHour);
  const minute = Number(data.pickupMinute);
  const name = String(data.customerName || '').trim();
  const phone = String(data.customerPhone || '').trim();
  const email = String(data.customerEmail || '').trim();
  const notes = String(data.notes || '').trim();
  const items = Array.isArray(data.items) ? data.items : [];

  if (![year, month, day, hour, minute].every(Number.isInteger) || month < 1 || month > 12 || day < 1 || day > 31 || hour < 10 || hour > 14 || minute !== 0) {
    throw new HttpsError('invalid-argument', '受取日時が正しくありません。');
  }
  const calendarDate = new Date(Date.UTC(year, month - 1, day));
  if (calendarDate.getUTCFullYear() !== year || calendarDate.getUTCMonth() !== month - 1 || calendarDate.getUTCDate() !== day) {
    throw new HttpsError('invalid-argument', '受取日が正しくありません。');
  }
  const validationError = validationErrorForPickup(year, month, day);
  if (validationError) throw new HttpsError('failed-precondition', validationError);
  if (!name || name.length > 100 || !phone || phone.length > 30 ||
      email.length > 254 || !/^\S+@\S+\.\S+$/.test(email) || notes.length > 1000) {
    throw new HttpsError('invalid-argument', 'お客様情報が正しくありません。');
  }
  if (items.length === 0 || items.some((item) =>
    !item || typeof item.name !== 'string' || item.name.trim() === '' ||
    item.name.length > 100 || !Number.isSafeInteger(item.quantity) ||
    item.quantity < 1 || item.quantity > 100 ||
    !Number.isSafeInteger(item.unitPrice) || item.unitPrice < 0 || item.unitPrice > 1000000)) {
    throw new HttpsError('invalid-argument', '注文内容が正しくありません。');
  }

  // JSTの日時を正しいUTC Timestampとして保存します。
  const pickupDate = new Date(Date.UTC(year, month - 1, day, hour - 9, minute));
  const orderCount = {};
  let totalPrice = 0;
  for (const item of items) {
    const safeName = String(item.name).slice(0, 100);
    orderCount[safeName] = (orderCount[safeName] || 0) + item.quantity;
    totalPrice += item.unitPrice * item.quantity;
  }
  const pickupDateStr = `${year}年${month}月${day}日（${weekDays[new Date(Date.UTC(year, month - 1, day)).getUTCDay()]}）`;
  const orderDetail = {
    userName: name, userPhone: phone, userEmail: email, totalPrice, orderCount,
    pickupDate: Timestamp.fromDate(pickupDate), notes: notes || 'なし',
    createdAt: FieldValue.serverTimestamp(),
  };
  const reservation = await new MailService(db).enqueueCustomerConfirmation({
    email,
    customerName: name,
    pickupDateLabel: pickupDateStr,
    hour,
    minute,
    orderCount,
    totalPrice,
    notes,
    orderDetail,
  });
  return { reservationId: reservation.id };
});

/**
 * 💡 注文内訳（商品名と個数）のHTMLリストを生成する共通関数（すっきり上品な仕切り線デザイン）
 */
function generateOrderListHtml(orderCountMap) {
  if (!orderCountMap || Object.keys(orderCountMap).length === 0) {
    return "<li style='list-style: none; color: #777;'>予約内容の取得に失敗しました、または内訳がありません。</li>";
  }

  let listHtml = "";
  for (const [productName, count] of Object.entries(orderCountMap)) {
    if (count > 0) {
      listHtml += `
            <li style="margin-bottom: 8px; list-style: none; border-bottom: 1px dashed #eee; padding-bottom: 8px; display: flex; justify-content: space-between; font-size: 14px;">
                <span>${escapeHtml(productName)}</span>
                <span style="font-weight: bold;">${count} 個</span>
            </li>`;
    }
  }
  return listHtml;
}

/**
 * ① 予約が入った時の【お店向け】即時通知メール機能
 */
exports.sendAdminNotification = onDocumentCreated({
  document: "mail/{mailId}",
  region: "asia-northeast1"
}, async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error("データが存在しません。");
    return null;
  }

  const data = snapshot.data();

  if (!data.orderDetail) {
    logger.log("orderDetail が含まれていないため、通知をスキップします。");
    return null;
  }

  // 💡 すでに自動送信されたメール、またはお店宛ての通知なら無限ループ防止のためスキップ
  if (data.to === SHOP_EMAIL) return null;

  const detail = data.orderDetail;
  const userName = detail.userName || "未入力";
  const userPhone = detail.userPhone || "未入力";
  const userEmail = detail.userEmail || "未入力";
  const totalPrice = detail.totalPrice || 0;
  const notesText = detail.notes || "なし";

  // 注文内訳（商品名と個数）のリストを生成
  const orderItemsHtml = generateOrderListHtml(detail.orderCount);

  // 受取日と「受取時間」のフォーマット
  let pickupDateStr = "未指定";
  let pickupTimeStr = "---";
  if (detail.pickupDate && typeof detail.pickupDate.toDate === "function") {
    const utcDate = detail.pickupDate.toDate();
    const jstDate = new Date(utcDate.getTime() + (9 * 60 * 60 * 1000)); // 日本時間（JST = UTC + 9時間）に補正

    // 💡 曜日を判定して取得
    const dayName = weekDays[jstDate.getUTCDay()];

    // 💡 曜日の文字（例:（金））を日付文字列に結合
    pickupDateStr = `${jstDate.getUTCFullYear()}年${jstDate.getUTCMonth() + 1}月${jstDate.getUTCDate()}日（${dayName}）`;
    const hours = String(jstDate.getUTCHours()).padStart(2, '0');
    const minutes = String(jstDate.getUTCMinutes()).padStart(2, '0');
    pickupTimeStr = `${hours}:${minutes}`;
  }
  logger.log(`新着予約を検知しました。注文者: ${userName} 様`);

  try {
    const emailHtml = `
        <div style="font-family: 'Helvetica Neue', Arial, 'Hiragino Kaku Gothic ProN', Meiryo, sans-serif; color: #444444; max-width: 560px; margin: 0 auto; padding: 20px 10px;">
          
          <div style="text-align: center; padding-bottom: 24px; border-bottom: 2px solid #5d4037;">
            <h2 style="margin: 0; font-size: 18px; color: #5d4037; letter-spacing: 1px;">【新着予約通知】</h2>
            <p style="margin: 8px 0 0 0; font-size: 13px; color: #777777;">店頭受取の予約が新しく入りました。内容は以下の通りです。</p>
          </div>
          
          <div style="padding-top: 24px;">
            <h3 style="font-size: 14px; font-weight: bold; color: #5d4037; border-left: 3px solid #8d6e63; padding-left: 8px; margin: 0 0 12px 0;">■ お客様情報</h3>
            <div style="background-color: #fafafa; border-radius: 6px; padding: 16px; border: 1px solid #eeeeee; margin-bottom: 24px;">
              <table style="width: 100%; font-size: 14px; border-collapse: collapse; line-height: 1.6;">
                <tr>
                  <td style="width: 90px; color: #777777; padding: 2px 0;">お名前</td>
                  <td style="font-weight: bold; color: #333333; padding: 2px 0;">${escapeHtml(userName)} 様</td>
                </tr>
                <tr>
                  <td style="color: #777777; padding: 2px 0;">お電話番号</td>
                  <td style="color: #333333; padding: 2px 0;">${escapeHtml(userPhone)}</td>
                </tr>
                <tr>
                  <td style="color: #777777; padding: 2px 0;">メールアドレス</td>
                  <td style="color: #333333; padding: 2px 0;">${escapeHtml(userEmail)}</td>
                </tr>
              </table>
            </div>
            
            <h3 style="font-size: 14px; font-weight: bold; color: #5d4037; border-left: 3px solid #8d6e63; padding-left: 8px; margin: 24px 0 12px 0;">■ ご予約日時</h3>
            <div style="background-color: #fafafa; border-radius: 6px; padding: 16px; border: 1px solid #eeeeee; margin-bottom: 24px;">
              <table style="width: 100%; font-size: 14px; border-collapse: collapse;">
                <tr>
                  <td style="width: 90px; padding: 4px 0; color: #777777;">受取日</td>
                  <td style="padding: 4px 0; font-weight: bold; color: #333333;">${pickupDateStr}</td>
                </tr>
                <tr>
                  <td style="padding: 4px 0; color: #777777;">時間枠</td>
                  <td style="padding: 4px 0; font-weight: bold; color: #d84315; font-size: 15px;">${pickupTimeStr} 頃</td>
                </tr>
              </table>
            </div>

            <h3 style="font-size: 14px; font-weight: bold; color: #5d4037; border-left: 3px solid #8d6e63; padding-left: 8px; margin: 24px 0 12px 0;">■ 予約商品内訳</h3>
            <div style="padding: 4px 8px; margin-bottom: 24px;">
              <ul style="padding: 0; margin: 0; font-size: 14px; color: #444444;">
                ${orderItemsHtml}
              </ul>
              <div style="text-align: right; margin-top: 12px; font-size: 15px; font-weight: bold; color: #333333;">
                合計金額: <span style="font-size: 18px; color: #d84315;">¥${totalPrice}</span>
              </div>
            </div>

            <h3 style="font-size: 14px; font-weight: bold; color: #5d4037; border-left: 3px solid #8d6e63; padding-left: 8px; margin: 24px 0 12px 0;">■ 備考欄（ご要望）</h3>
            <div style="background-color: #fdfdfd; padding: 12px; border-radius: 6px; white-space: pre-wrap; font-size: 13px; border: 1px solid #eeeeee; color: #666666; line-height: 1.5;">${escapeHtml(notesText).replace(/\n/g, '<br>')}</div>
            
            <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #eeeeee; text-align: center;">
              <p style="font-size: 11px; color: #999999; margin: 0;">
                ※詳細は管理画面、またはFirestoreのデータベースをご確認ください。<br>
                こめひろ 店頭予約システム
              </p>
            </div>
          </div>
        </div>
        `;

    await db.collection("mail").add({
      to: SHOP_EMAIL,
      message: {
        subject: `【新着予約通知】${userName} 様よりご予約が入りました`,
        html: emailHtml,
      }
    });
    logger.log("お店向けの即時通知メールの作成に成功しました。");
  } catch (error) {
    logger.error("即時通知メールの作成中にエラーが発生しました:", error);
  }
  return null;
});

/**
 * ② 予約当日の朝に【お客様向け】一斉リマインドメールを自動送信する機能（毎朝8時）
 */
exports.sendDailyReminder = onSchedule({
  schedule: "0 8 * * *",
  timeZone: "Asia/Tokyo",
  region: "asia-northeast1"
}, async (event) => {
  logger.log("予約当日リマインドメールの定期処理を開始します。");

  const nowTimestamp = Date.now();
  const jstOffset = 9 * 60 * 60 * 1000;
  const jstNow = new Date(nowTimestamp + jstOffset);

  // 日本時間の今日の「0時0分0秒」を世界標準時（UTC）のタイムスタンプに逆算
  const startOfTodayJst = new Date(Date.UTC(jstNow.getUTCFullYear(), jstNow.getUTCMonth(), jstNow.getUTCDate(), 0, 0, 0));
  const startSearch = new Date(startOfTodayJst.getTime() - jstOffset);
  const endSearch = new Date(startSearch.getTime() + (24 * 60 * 60 * 1000) - 1);

  // 💡 今日の曜日を取得
  const todayDayName = weekDays[jstNow.getUTCDay()];

  // メールの文面で使う日付文字列に曜日を追加（「2026年6月12日（金）」の形式）
  const todayStr = `${jstNow.getUTCFullYear()}年${jstNow.getUTCMonth() + 1}月${jstNow.getUTCDate()}日（${todayDayName}）`;

  try {
    const snapshot = await db.collection("mail")
      .where("orderDetail.pickupDate", ">=", Timestamp.fromDate(startSearch))
      .where("orderDetail.pickupDate", "<=", Timestamp.fromDate(endSearch))
      .get();

    if (snapshot.empty) {
      logger.log("本日受取予定の予約データはありませんでした。");
      return null;
    }

    logger.log(`本日受取予定 of 予約を ${snapshot.size} 件検出しました。リマインドメールを作成します。`);

    const promises = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      const detail = data.orderDetail;

      const userEmail = detail.userEmail;
      const userName = detail.userName || "お客様";
      const totalPrice = detail.totalPrice || 0;

      // 注文内訳のリストを生成
      const orderItemsHtml = generateOrderListHtml(detail.orderCount);

      // 受取時間のフォーマット
      let reminderTimeStr = "---";
      if (detail.pickupDate && typeof detail.pickupDate.toDate === "function") {
        const utcDate = detail.pickupDate.toDate();
        const jstDate = new Date(utcDate.getTime() + (9 * 60 * 60 * 1000));

        const hours = String(jstDate.getUTCHours()).padStart(2, '0');
        const minutes = String(jstDate.getUTCMinutes()).padStart(2, '0');
        reminderTimeStr = `${hours}:${minutes}`;
      }

      if (userEmail) {
        // 💡 朝8時にお客様へ届くリマインドメールも、すっきり上品なブラウン調に統一
        const reminderHtml = `
                <div style="font-family: 'Helvetica Neue', Arial, 'Hiragino Kaku Gothic ProN', Meiryo, sans-serif; color: #444444; max-width: 560px; margin: 0 auto; padding: 20px 10px;">
                  
                  <div style="text-align: center; padding-bottom: 24px; border-bottom: 2px solid #6d4c41;">
                    <h2 style="margin: 0; font-size: 18px; color: #5d4037; letter-spacing: 1px;">本日お受取り日です</h2>
                    <p style="margin: 8px 0 0 0; font-size: 13px; color: #777777;">おはようございます。ご来店を心よりお待ちしております。</p>
                  </div>
                  
                  <div style="padding-top: 24px;">
                    <p style="font-size: 14px; margin-bottom: 20px;">${escapeHtml(userName)} 様</p>
                    <p style="font-size: 14px; line-height: 1.6; color: #555555;">本日、ご予約いただいた商品のお受取り日となっております。<br>どうぞお気をつけてお越しくださいませ。</p>
                    
                    <h3 style="font-size: 14px; font-weight: bold; color: #5d4037; border-left: 3px solid #8d6e63; padding-left: 8px; margin: 28px 0 12px 0;">■ ご予約内容</h3>
                    <div style="background-color: #fafafa; border-radius: 6px; padding: 16px; border: 1px solid #eeeeee;">
                      <table style="width: 100%; font-size: 14px; border-collapse: collapse;">
                        <tr>
                          <td style="width: 70px; padding: 4px 0; color: #777777;">受取日</td>
                          <td style="padding: 4px 0; font-weight: bold; color: #333333;">本日 ${todayStr}</td>
                        </tr>
                        <tr>
                          <td style="padding: 4px 0; color: #777777;">時間枠</td>
                          <td style="padding: 4px 0; font-weight: bold; color: #d84315; font-size: 15px;">${reminderTimeStr} 頃</td>
                        </tr>
                      </table>
                    </div>

                    <h3 style="font-size: 14px; font-weight: bold; color: #5d4037; border-left: 3px solid #8d6e63; padding-left: 8px; margin: 28px 0 12px 0;">■ お受取り商品内訳</h3>
                    <div style="padding: 4px 8px;">
                      <ul style="padding: 0; margin: 0; font-size: 14px; color: #444444;">
                        ${orderItemsHtml}
                      </ul>
                      <div style="text-align: right; margin-top: 12px; font-size: 15px; font-weight: bold; color: #333333;">
                        合計金額: <span style="font-size: 18px; color: #d84315;">¥${totalPrice}</span>
                      </div>
                    </div>
                    
                    <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #eeeeee; text-align: center;">
                      <p style="font-size: 12px; color: #888888; margin: 0; line-height: 1.6;">
                        みなさまのご来店を心よりお待ちしております。<br>
                        <span style="font-weight: bold; color: #5d4037; font-size: 13px;">米粉パン専門店 こめひろ</span>
                      </p>
                    </div>
                  </div>
                </div>
                `;

        const mailPromise = db.collection("mail").add({
          to: userEmail,
          message: {
            subject: "【こめひろ】本日お受取り日です（リマインド）",
            html: reminderHtml
          }
        });
        promises.push(mailPromise);
      }
    });

    await Promise.all(promises);
    logger.log(`合計 ${promises.length} 件のリマインドメール作成が完了しました。`);
  } catch (error) {
    logger.error("リマインドメール送信処理中にエラーが発生しました:", error);
  }
  return null;
});
