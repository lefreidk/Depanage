/// نوع نتيجة بسيط يجنّبنا رمي Exception بنص عربي عشوائي في كل مكان،
/// ويسمح للواجهة بالتفريع حسب نوع الخطأ (شبكة/تحقق/خادم) بدل مقارنة نصوص.
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(AppFailure failure) = Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Failure<T>) return failure(self.failure);
    throw StateError('Unreachable');
  }

  bool get isSuccess => this is Success<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}

enum FailureType { network, validation, unauthorized, server, unknown }

class AppFailure {
  final FailureType type;
  final String message;

  const AppFailure(this.type, this.message);

  factory AppFailure.network([String? msg]) =>
      AppFailure(FailureType.network, msg ?? 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت');

  factory AppFailure.unauthorized([String? msg]) =>
      AppFailure(FailureType.unauthorized, msg ?? 'انتهت صلاحية الجلسة، الرجاء تسجيل الدخول مجدداً');

  factory AppFailure.server([String? msg]) => AppFailure(FailureType.server, msg ?? 'حدث خطأ في الخادم');

  factory AppFailure.validation(String msg) => AppFailure(FailureType.validation, msg);
}
