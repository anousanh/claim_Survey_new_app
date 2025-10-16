// lib/widgets/case_detail/navigation_buttons.dart
import 'package:flutter/material.dart';

class CheckInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const CheckInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0099FF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'ຄຳນວນໄລຍະທາງ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class NavigationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NavigationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0099FF),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.navigation, color: Colors.white),
          label: const Text(
            'ເລີ່ມນຳທາງ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class StopNavigationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StopNavigationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.stop, color: Colors.white),
          label: const Text(
            'ຢຸດນຳທາງ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class ArriveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double? currentDistance;
  final bool isLoading;

  const ArriveButton({
    super.key,
    required this.onPressed,
    this.currentDistance,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final canMarkArrival = currentDistance != null && currentDistance! < 0.1;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (currentDistance != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canMarkArrival ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: canMarkArrival ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canMarkArrival ? Icons.check_circle : Icons.info,
                    color: canMarkArrival ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      canMarkArrival
                          ? 'ທ່ານໃກ້ເຖິງຈຸດໝາຍແລ້ວ'
                          : 'ໄລຍະຫ່າງ: ${currentDistance!.toStringAsFixed(2)} ກມ',
                      style: TextStyle(
                        color: canMarkArrival
                            ? Colors.green[900]
                            : Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.flag, color: Colors.white),
              label: Text(
                isLoading ? 'ກຳລັງບັນທຶກ...' : 'ເຂົ້າເຮັດວຽກ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
