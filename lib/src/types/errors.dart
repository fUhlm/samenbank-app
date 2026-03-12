class DomainError implements Exception {
  final String message;
  const DomainError(this.message);

  @override
  String toString() => 'DomainError: $message';
}

class InvalidMonthError extends DomainError {
  final int month;
  const InvalidMonthError(this.month) : super('Invalid month: $month');
}

class DuplicateTaxonKeyError extends DomainError {
  const DuplicateTaxonKeyError(super.message);
}

class InvalidContainerAssignmentError extends DomainError {
  const InvalidContainerAssignmentError(super.message);
}

class InvalidTubeCodeError extends DomainError {
  const InvalidTubeCodeError(super.message);
}
