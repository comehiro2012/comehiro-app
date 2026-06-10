// product_data.dart

final List<Map<String, dynamic>> allProducts = [
  // ==========================================
  // --- 食パン（同じ商品のロング・ハーフを隣り合わせに配置） ---
  // ==========================================

  // 1. プレーン米粉パン
  {
    'name': 'プレーン米粉パン（ロング）',
    'price': 410,
    'category': '食パン',
    'limit_weekday': 10,
    'limit_weekend': 10,
    'allergies': ['豚肉'],
  },
  {
    'name': 'プレーン米粉パン（ハーフ）',
    'price': 205,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 10,
    'allergies': ['豚肉'],
  },

  // 2. 玄米パン
  {
    'name': '玄米パン（ロング）',
    'price': 540,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': [],
  },
  {
    'name': '玄米パン（ハーフ）',
    'price': 270,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': [],
  },

  // 3. かぼちゃパン
  {
    'name': 'かぼちゃパン（ロング）',
    'price': 550,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['乳'],
  },
  {
    'name': 'かぼちゃパン（ハーフ）',
    'price': 275,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['乳'],
  },

  // 4. アールグレイ
  {
    'name': 'アールグレイ（ロング）',
    'price': 630,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },
  {
    'name': 'アールグレイ（ハーフ）',
    'price': 315,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },

  // 5. 黒ごま
  {
    'name': '黒ごま（ロング）',
    'price': 510,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉', 'ごま'],
  },
  {
    'name': '黒ごま（ハーフ）',
    'price': 255,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉', 'ごま'],
  },

  // 6. レーズンパン
  {
    'name': 'レーズンパン（ロング）',
    'price': 510,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },
  {
    'name': 'レーズンパン（ハーフ）',
    'price': 255,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },

  // 7. クルミいちじくパン
  {
    'name': 'クルミいちじくパン（ロング）',
    'price': 700,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },
  {
    'name': 'クルミいちじくパン（ハーフ）',
    'price': 350,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },

  // 8. さつまパン
  {
    'name': 'さつまパン（ロング）',
    'price': 500,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },
  {
    'name': 'さつまパン（ハーフ）',
    'price': 250,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },

  // 9. ココアマーブルパン
  {
    'name': 'ココアマーブルパン（ロング）',
    'price': 510,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },
  {
    'name': 'ココアマーブルパン（ハーフ）',
    'price': 255,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },

  // 10. チーズパン
  {
    'name': 'チーズパン（ロング）',
    'price': 590,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['乳', '豚肉'],
  },
  {
    'name': 'チーズパン（ハーフ）',
    'price': 295,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['乳', '豚肉'],
  },

  // 11. クランベリーパン
  {
    'name': 'クランベリーパン（ロング）',
    'price': 540,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },
  {
    'name': 'クランベリーパン（ハーフ）',
    'price': 270,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },

  // 12. チョコチップパン
  {
    'name': 'チョコチップパン（ロング）',
    'price': 550,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['乳', '豚肉'],
  },
  {
    'name': 'チョコチップパン（ハーフ）',
    'price': 275,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['乳', '豚肉'],
  },

  // 13. 伊予柑ピールパン
  {
    'name': '伊予柑ピールパン（ロング）',
    'price': 620,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },
  {
    'name': '伊予柑ピールパン（ハーフ）',
    'price': 310,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },

  // 14. あずきパン
  {
    'name': 'あずきパン（ロング）',
    'price': 510,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },
  {
    'name': 'あずきパン（ハーフ）',
    'price': 255,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },

  // 15. くるみパン
  {
    'name': 'くるみパン（ロング）',
    'price': 700,
    'category': '食パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },
  {
    'name': 'くるみパン（ハーフ）',
    'price': 350,
    'category': '食パン',
    'limit_weekday': 0,
    'limit_weekend': 5,
    'allergies': ['豚肉'],
  },

  // ==========================================
  // --- 調理パン ---
  // ==========================================
  {
    'name': 'ウィンナーパン（ケチャップ）',
    'price': 245,
    'category': '調理パン',
    'limit_weekday': 8,
    'limit_weekend': 10,
    'allergies': ['豚肉', '牛肉', '大豆'],
  },
  {
    'name': 'ウィンナーパン（マスタード）',
    'price': 245,
    'category': '調理パン',
    'limit_weekday': 8,
    'limit_weekend': 10,
    'allergies': ['豚肉', '牛肉', '大豆'],
  },
  {
    'name': 'ツナマヨパン',
    'price': 245,
    'category': '調理パン',
    'limit_weekday': 8,
    'limit_weekend': 10,
    'allergies': ['豚肉', '大豆'],
  },
  {
    'name': 'ベーコンポテト',
    'price': 255,
    'category': '調理パン',
    'limit_weekday': 0,
    'limit_weekend': 10,
    'allergies': ['乳', '豚肉'],
  },
  {
    'name': 'アボカドチーズ',
    'price': 260,
    'category': '調理パン',
    'limit_weekday': 8,
    'limit_weekend': 10,
    'allergies': ['乳', '豚肉'],
  },
  {
    'name': 'スパイシードッグパン',
    'price': 280,
    'category': '調理パン',
    'limit_weekday': 8,
    'limit_weekend': 10,
    'allergies': ['乳', '豚肉', '牛肉', '大豆'],
  },
  {
    'name': 'チーズカレーパン',
    'price': 260,
    'category': '調理パン',
    'limit_weekday': 0,
    'limit_weekend': 10,
    'allergies': ['乳', '豚肉', '大豆'],
  },
  {
    'name': 'コロッケパン',
    'price': 240,
    'category': '調理パン',
    'limit_weekday': 0,
    'limit_weekend': 8,
    'allergies': ['豚肉'],
  },
  {
    'name': 'ブルーチーズ',
    'price': 185,
    'category': '調理パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': ['乳', '豚肉'],
  },
  {
    'name': 'コーンパン',
    'price': 185,
    'category': '調理パン',
    'limit_weekday': 0,
    'limit_weekend': 10,
    'allergies': ['乳'],
  },
  {
    'name': 'マルゲリータ',
    'price': 245,
    'category': '調理パン',
    'limit_weekday': 10,
    'limit_weekend': 10,
    'allergies': ['乳', '大豆', 'りんご'],
  },
  {
    'name': 'サラミ&オリーブピザ',
    'price': 255,
    'category': '調理パン',
    'limit_weekday': 10,
    'limit_weekend': 10,
    'allergies': ['乳', '豚肉', '牛肉', '大豆'],
  },
  {
    'name': 'コッペパン（2本入）',
    'price': 300,
    'category': '調理パン',
    'limit_weekday': 0,
    'limit_weekend': 10,
    'allergies': [],
  },
  {
    'name': '丸パン',
    'price': 150,
    'category': '調理パン',
    'limit_weekday': 0,
    'limit_weekend': 10,
    'allergies': [],
  },
  {
    'name': 'ピザ生地',
    'price': 400,
    'category': '調理パン',
    'limit_weekday': 5,
    'limit_weekend': 5,
    'allergies': [],
  },

  // ==========================================
  // --- 菓子パン ---
  // ==========================================
  {
    'name': 'ワッフル',
    'price': 185,
    'category': '菓子パン',
    'limit_weekday': 12,
    'limit_weekend': 12,
    'allergies': ['大豆'],
  },
  {
    'name': 'チョコチップワッフル',
    'price': 210,
    'category': '菓子パン',
    'limit_weekday': 12,
    'limit_weekend': 12,
    'allergies': ['乳', '大豆'],
  },
  {
    'name': 'お芋ドーナツ',
    'price': 185,
    'category': '菓子パン',
    'limit_weekday': 9,
    'limit_weekend': 12,
    'allergies': ['豚肉'],
  },
  {
    'name': 'ココアドーナツ',
    'price': 185,
    'category': '菓子パン',
    'limit_weekday': 9,
    'limit_weekend': 12,
    'allergies': ['乳', '豚肉', '大豆'],
  },
  {
    'name': '黒糖パン',
    'price': 190,
    'category': '菓子パン',
    'limit_weekday': 9,
    'limit_weekend': 9,
    'allergies': ['豚肉'],
  },
  {
    'name': 'レーズン黒糖パン',
    'price': 205,
    'category': '菓子パン',
    'limit_weekday': 9,
    'limit_weekend': 9,
    'allergies': ['豚肉'],
  },
  {
    'name': '塩バターパン',
    'price': 160,
    'category': '菓子パン',
    'limit_weekday': 0,
    'limit_weekend': 9,
    'allergies': ['乳'],
  },
  {
    'name': 'クリームチーズパン',
    'price': 235,
    'category': '菓子パン',
    'limit_weekday': 0,
    'limit_weekend': 9,
    'allergies': ['乳'],
  },
  {
    'name': 'いちごジャム',
    'price': 165,
    'category': '菓子パン',
    'limit_weekday': 9,
    'limit_weekend': 9,
    'allergies': ['豚肉'],
  },
  {
    'name': 'つぶあんぱん',
    'price': 165,
    'category': '菓子パン',
    'limit_weekday': 9,
    'limit_weekend': 9,
    'allergies': ['豚肉'],
  },
  {
    'name': 'レモンあんぱん',
    'price': 185,
    'category': '菓子パン',
    'limit_weekday': 9,
    'limit_weekend': 9,
    'allergies': ['豚肉'],
  },
];
