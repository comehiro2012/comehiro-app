function escapeHtml(value) {
  return String(value).replace(/[&<>'"]/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    "'": '&#39;',
    '"': '&quot;',
  }[char]));
}

function orderListHtml(orderCount) {
  return Object.entries(orderCount).map(([name, quantity]) =>
    `<li style="margin-bottom:8px;list-style:none;border-bottom:1px dashed #eee;padding-bottom:8px;display:flex;justify-content:space-between"><span>${escapeHtml(name)}</span><span style="font-weight:bold">${quantity} 個</span></li>`
  ).join('');
}

/// Firebase Extension が監視している mail コレクションへ確認メールを登録します。
class MailService {
  constructor(db) {
    this.db = db;
  }

  async enqueueCustomerConfirmation({ email, customerName, pickupDateLabel, hour, minute, orderCount, totalPrice, notes, orderDetail }) {
    const time = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
    const html = `<div style="font-family:Arial,sans-serif;color:#444;max-width:560px;margin:auto;padding:20px"><h2 style="color:#5d4037">ご予約ありがとうございます</h2><p>${escapeHtml(customerName)} 様</p><h3>■ ご予約日時</h3><p>${pickupDateLabel} ${time} 頃</p><h3>■ お受取り商品内訳</h3><ul style="padding:0">${orderListHtml(orderCount)}</ul><p style="text-align:right;font-weight:bold">合計金額: ¥${totalPrice}</p><h3>■ 備考欄</h3><p>${escapeHtml(notes || 'なし').replace(/\n/g, '<br>')}</p></div>`;
    return this.db.collection('mail').add({
      to: email,
      message: { subject: '【こめひろ】店頭受取のご予約を承りました', html },
      orderDetail,
    });
  }
}

module.exports = { MailService };
