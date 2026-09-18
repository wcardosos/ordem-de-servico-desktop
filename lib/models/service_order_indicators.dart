class ServiceOrderIndicators {
  const ServiceOrderIndicators({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.awaitingPart,
    required this.completed,
    required this.urgent,
    required this.overdue,
    required this.totalAmount,
  });

  const ServiceOrderIndicators.empty()
    : total = 0,
      open = 0,
      inProgress = 0,
      awaitingPart = 0,
      completed = 0,
      urgent = 0,
      overdue = 0,
      totalAmount = 0;

  final int total;

  final int open;

  final int inProgress;

  final int awaitingPart;

  final int completed;

  final int urgent;

  final int overdue;

  final double totalAmount;
}
