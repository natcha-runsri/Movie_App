class PromotionModel {
  String promotion_detail;
  String image_url;
  String promotion_name;
  String validitty_period;



  static const CollectionName = 'promotion';

  PromotionModel({
    required this.promotion_detail,
    required this.image_url,
    required this.promotion_name,
    required this.validitty_period,

  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      promotion_detail: json['detail'],
      image_url: json['image'],
      promotion_name: json['name'],
      validitty_period: json['valid'],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail': promotion_detail,
      'image': image_url,
      'name': promotion_name,
      'valid': validitty_period, 
    };
  }
}
