class JobDraft {
  final String title;
  final String description;
  final String category;
  final String categoryId;
  final double pay;
  final String payType;
  final int workersRequired;
  final DateTime? date;
  final String address;

  const JobDraft({
    this.title = '',
    this.description = '',
    this.category = '',
    this.categoryId = '',
    this.pay = 0,
    this.payType = 'fixed',
    this.workersRequired = 1,
    this.date,
    this.address = '',
  });

  JobDraft copyWith({
    String? title,
    String? description,
    String? category,
    String? categoryId,
    double? pay,
    String? payType,
    int? workersRequired,
    DateTime? date,
    String? address,
  }) {
    return JobDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      pay: pay ?? this.pay,
      payType: payType ?? this.payType,
      workersRequired: workersRequired ?? this.workersRequired,
      date: date ?? this.date,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson({double? lat, double? lng}) {
    return {
      'title': title,
      'description': description,
      'category': categoryId.isNotEmpty ? categoryId : category,
      'categoryName': category,
      'pay': pay,
      'amount': pay,
      'payType': payType,
      'workersRequired': workersRequired,
      if (date != null) 'date': date!.toIso8601String(),
      'address': address,
      if (lat != null && lng != null) ...{
        'lat': lat,
        'lng': lng,
        'location': {
          'type': 'Point',
          'coordinates': [lng, lat],
        },
      },
    };
  }
}
