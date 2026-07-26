import '../models/product.dart';
import '../product_data.dart';

/// 既存の商品マスタを、画面で安全に使えるProductへ一度だけ変換します。
final List<Product> productCatalog = allProducts
    .map(Product.fromLegacyMap)
    .toList(growable: false);
