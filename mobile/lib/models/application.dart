import '../core/network/json_helpers.dart';
import 'job.dart';
import 'user.dart';

class Application {
  final String id;
  final String jobId;
  final String workerId;
  final String status;
  final String? message;
  final Job? job;
  final User? worker;
  final String? chatId;
  final DateTime? createdAt;

  const Application({
    required this.id,
    required this.jobId,
    required this.workerId,
    this.status = 'applied',
    this.message,
    this.job,
    this.worker,
    this.chatId,
    this.createdAt,
  });

  bool get isApplied => status == 'applied' || status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  factory Application.fromJson(Map<String, dynamic> json) {
    Job? job;
    if (json['job'] is Map) job = Job.fromJson(asMap(json['job']));
    User? worker;
    if (json['worker'] is Map) {
      worker = User.fromJson(asMap(json['worker']));
    } else if (json['applicant'] is Map) {
      worker = User.fromJson(asMap(json['applicant']));
    }

    return Application(
      id: readId(json),
      jobId: _jobIdFrom(json, job),
      workerId: readString(json, ['workerId', 'userId', 'applicantId']) ?? worker?.id ?? '',
      status: (readString(json, ['status']) ?? 'applied').toLowerCase(),
      message: readString(json, ['message', 'note', 'cover']),
      job: job,
      worker: worker,
      chatId: readString(json, ['chatId']),
      createdAt: readDate(json['createdAt']),
    );
  }
}

String _jobIdFrom(Map<String, dynamic> json, Job? job) {
  final raw = json['jobId'];
  if (raw is Map) return readId(asMap(raw));
  final direct = readString(json, ['jobId']);
  if (direct != null && direct.isNotEmpty) return direct;
  return job?.id ?? '';
}
