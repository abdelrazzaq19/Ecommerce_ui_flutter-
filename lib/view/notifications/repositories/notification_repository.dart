import 'package:ecommerce_ui/view/notifications/models/notification_type.dart';

class NotificationRepository {
  List<NotificationItem> getNotifications() {
    return [
      NotificationItem(
        title: "Order Confirmed",
        message: "Your order #1234 has been confirmed and is being processed.",
        time: "2 minutes ago",
        type: NotificationType.order,
        isRead: true,
      ),
      NotificationItem(
        title: "Special Offer!",
        message: "Get 20% off an all shoes this weekend",
        time: "1 hour ago",
        type: NotificationType.promo,
        isRead: true,
      ),
      NotificationItem(
        title: "Out for delivery",
        message: "Your order #1234 is out for delivery",
        time: "3 hour ago",
        type: NotificationType.delivery,
        isRead: true,
      ),
      NotificationItem(
        title: "Payment Successful",
        message: "payment for order #4323234 was successful",
        time: "2 minutes ago",
        type: NotificationType.payment,
        isRead: true,
      ),
    ];
  }
}
