const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

// Firebase Admin SDK の初期化
initializeApp();
const db = getFirestore();

// お店の通知用メールアドレス
const SHOP_EMAIL = "comehiro.2012@gmail.com";

/**
 * 💡 注文内訳（商品名と個数）のHTMLリストを生成する共通関数
 */
function generateOrderListHtml(orderCountMap) {
    if (!orderCountMap || Object.keys(orderCountMap).length === 0) {
        return "<li>予約内容の取得に失敗しました、または内訳がありません。</li>";
    }

    let listHtml = "";
    for (const [productName, count] of Object.entries(orderCountMap)) {
        if (count > 0) {
            listHtml += `<li style="margin-bottom: 4px;"><strong>${productName}</strong> × ${count}個</li>`;
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

    const detail = data.orderDetail;
    const userName = detail.userName || "未入力";
    const userPhone = detail.userPhone || "未入力";
    const userEmail = detail.userEmail || "未入力";
    const totalPrice = detail.totalPrice || 0;
    const notes = detail.notes || "なし";

    // ★ 注文内訳（商品名と個数）のリストを生成
    const orderItemsHtml = generateOrderListHtml(detail.orderCount);

    // 受取日のフォーマット
    let pickupDateStr = "未指定";
    if (detail.pickupDate && typeof detail.pickupDate.toDate === "function") {
        const pDate = detail.pickupDate.toDate();
        pickupDateStr = `${pDate.getFullYear()}/${pDate.getMonth() + 1}/${pDate.getDate()}`;
    }

    logger.log(`新着予約を検知しました。注文者: ${userName} 様`);

    try {
        await db.collection("mail").add({
            to: SHOP_EMAIL,
            message: {
                subject: `【新着予約通知】${userName} 様よりご予約が入りました`,
                html: `
          <h3>【こめひろ 店頭予約システム】</h3>
          <p>新しく店頭受取の予約が入りました。内容は以下の通りです。</p>
          <hr>
          <p><strong>■ お客様情報</strong></p>
          <ul>
            <li><strong>お名前:</strong> ${userName} 様</li>
            <li><strong>お電話番号:</strong> ${userPhone}</li>
            <li><strong>メールアドレス:</strong> ${userEmail}</li>
          </ul>
          <p><strong>■ 予約内容</strong></p>
          <ul>
            <li><strong>受取日:</strong> <span style="font-size: 16px; color: red; font-weight: bold;">${pickupDateStr}</span></li>
            <li><strong>合計金額:</strong> ¥${totalPrice}</li>
          </ul>
          <p><strong>■ 予約商品内訳</strong></p>
          <ul style="background-color: #f8f9fa; padding: 12px 24px; border-radius: 4px; list-style-type: square;">
            ${orderItemsHtml}
          </ul>
          <p><strong>■ 備考欄（ご要望）:</strong></p>
          <div style="background-color: #fff3cd; padding: 8px 12px; border-radius: 4px; white-space: pre-wrap;">${notes}</div>
          <hr>
          <p>※詳細は管理画面、またはFirestoreのデータベースをご確認ください。</p>
        `,
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

    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);

    try {
        const snapshot = await db.collection("mail")
            .where("orderDetail.pickupDate", ">=", Timestamp.fromDate(startOfToday))
            .where("orderDetail.pickupDate", "<=", Timestamp.fromDate(endOfToday))
            .get();

        if (snapshot.empty) {
            logger.log("本日受取予定の予約データはありませんでした。");
            return null;
        }

        logger.log(`本日受取予定の予約を ${snapshot.size} 件検出しました。リマインドメールを作成します。`);

        const promises = [];
        snapshot.forEach((doc) => {
            const data = doc.data();
            const detail = data.orderDetail;

            const userEmail = detail.userEmail;
            const userName = detail.userName;
            const totalPrice = detail.totalPrice;

            // ★ お客様ごとの注文内訳（商品名と個数）のリストを生成
            const orderItemsHtml = generateOrderListHtml(detail.orderCount);

            if (userEmail) {
                const mailPromise = db.collection("mail").add({
                    to: userEmail,
                    message: {
                        subject: "【こめひろ】本日お受取り日です（リマインド）",
                        html: `
              <p>${userName} 様</p>
              <p>おはようございます。こめひろです。</p>
              <p>本日、ご予約いただいた米粉パンのお受取り日となっております。ご来店を心よりお待ちしております！</p>
              <hr>
              <p><strong>■ ご予約内容</strong></p>
              <ul>
                <li><strong>お受取日:</strong> 本日 (${startOfToday.getFullYear()}/${startOfToday.getMonth() + 1}/${startOfToday.getDate()})</li>
                <li><strong>合計金額:</strong> ¥${totalPrice}</li>
              </ul>
              <p><strong>■ お受取り商品内訳</strong></p>
              <ul style="background-color: #f8f9fa; padding: 12px 24px; border-radius: 4px; list-style-type: square; color: #333;">
                ${orderItemsHtml}
              </ul>
              <hr>
              <p>お気をつけてお越しくださいませ。</p>
            `
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