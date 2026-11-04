import 'package:flutter/material.dart';
import '../data/lieutenants.dart';

class LieutenantsPanel extends StatelessWidget {
  final List<Lieutenant> lieutenants;
  final int playerCredits;
  final Function(Lieutenant) onHire;

  const LieutenantsPanel({
    Key? key,
    required this.lieutenants,
    required this.playerCredits,
    required this.onHire,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SYNDICATE ROSTER & CREW',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Divider(color: Colors.cyan.shade800),
          ...lieutenants.map((lieutenant) {
            bool canAfford = playerCredits >= lieutenant.cost;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          lieutenant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.cyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          lieutenant.role,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(lieutenant.description, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${lieutenant.cost} ¢', style: const TextStyle(color: Colors.amberAccent, fontFamily: 'monospace')),
                      lieutenant.hired
                          ? const Text('ACTIVE', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11))
                          : ElevatedButton(
                              onPressed: canAfford ? () => onHire(lieutenant) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan[700],
                                disabledBackgroundColor: Colors.grey[800],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              child: const Text('Recruit', style: TextStyle(fontSize: 11)),
                            ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}