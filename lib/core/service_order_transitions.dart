import 'service_order_labels.dart';
import 'service_order_status.dart';
import 'transition_result.dart';

const Map<ServiceOrderStatus, List<ServiceOrderStatus>> validTransitions =
    <ServiceOrderStatus, List<ServiceOrderStatus>>{
      ServiceOrderStatus.open: <ServiceOrderStatus>[
        ServiceOrderStatus.assigned,
        ServiceOrderStatus.cancelled,
      ],
      ServiceOrderStatus.assigned: <ServiceOrderStatus>[
        ServiceOrderStatus.inProgress,
        ServiceOrderStatus.cancelled,
      ],
      ServiceOrderStatus.inProgress: <ServiceOrderStatus>[
        ServiceOrderStatus.awaitingPart,
        ServiceOrderStatus.completed,
        ServiceOrderStatus.cancelled,
      ],
      ServiceOrderStatus.awaitingPart: <ServiceOrderStatus>[
        ServiceOrderStatus.inProgress,
        ServiceOrderStatus.cancelled,
      ],
      ServiceOrderStatus.completed: <ServiceOrderStatus>[],
      ServiceOrderStatus.cancelled: <ServiceOrderStatus>[],
    };

String transitionBlockedMessage(
  TransitionResult result,
  ServiceOrderStatus current,
  ServiceOrderStatus target,
) => switch (result) {
  TransitionResult.allowed => '',
  TransitionResult.invalidTarget =>
    'Não é possível mudar de ${current.label} para ${target.label}.',
  TransitionResult.technicianNotSet =>
    'Defina o técnico responsável antes de atribuir a ordem.',
  TransitionResult.missingDiagnosisAndSolution =>
    'Informe o diagnóstico ou a solução antes de concluir a ordem.',
};
