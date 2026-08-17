import '../core/network/json_helpers.dart';

class EarningsSummary {
  final double total;
  final double thisMonth;
  final double pending;
  final int completedJobs;

  const EarningsSummary({
    this.total = 0,
    this.thisMonth = 0,
    this.pending = 0,
    this.completedJobs = 0,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      total: readDouble(json['total'] ?? json['totalEarned'] ?? json['lifetime']) ?? 0,
      thisMonth: readDouble(json['thisMonth'] ?? json['month']) ?? 0,
      pending: readDouble(json['pending'] ?? json['inProgress']) ?? 0,
      completedJobs: readInt(json['completedJobs'] ?? json['jobsCompleted']) ?? 0,
    );
  }
}

class Txn {
  final String id;
  final String uniqueTxnId;
  final String type;
  final double gross;
  final double commission;
  final double net;
  final String status;
  final String? note;
  final DateTime? createdAt;

  const Txn({
    required this.id,
    this.uniqueTxnId = '',
    this.type = 'earning',
    this.gross = 0,
    this.commission = 0,
    this.net = 0,
    this.status = 'paid',
    this.note,
    this.createdAt,
  });

  factory Txn.fromJson(Map<String, dynamic> json) {
    return Txn(
      id: readId(json),
      uniqueTxnId: readString(json, ['uniqueTxnId', 'txnId', 'reference']) ?? '',
      type: readString(json, ['type', 'kind']) ?? 'earning',
      gross: readDouble(json['gross'] ?? json['amount']) ?? 0,
      commission: readDouble(json['commission']) ?? 0,
      net: readDouble(json['net'] ?? json['amount']) ?? 0,
      status: readString(json, ['status', 'paymentStatus']) ?? 'paid',
      note: readString(json, ['note', 'title', 'description', 'jobTitle']),
      createdAt: readDate(json['createdAt']),
    );
  }
}
