
import 'package:flutter/material.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);
const _gold = Color(0xFFFBC02D);

class SystemHealthPage extends StatefulWidget {
  const SystemHealthPage({super.key});

  @override
  State<SystemHealthPage> createState() =>
      _SystemHealthPageState();
}

class _SystemHealthPageState extends State<SystemHealthPage> {
  String _selectedFilter = 'All';

  // Prototype data only. No real health checks are performed.
  static const _services = <_DemoService>[
    _DemoService(
      'Supabase Database',
      'Database',
      'Operational',
      'Sample database status',
      Icons.storage_rounded,
    ),
    _DemoService(
      'Authentication Service',
      'Authentication',
      'Operational',
      'Sample authentication status',
      Icons.lock_outline_rounded,
    ),
    _DemoService(
      'Application API',
      'API',
      'Degraded',
      'Sample API performance warning',
      Icons.api_rounded,
    ),
    _DemoService(
      'Notification Service',
      'Notifications',
      'Operational',
      'Sample notification status',
      Icons.notifications_active_outlined,
    ),
    _DemoService(
      'File Storage',
      'Storage',
      'Unknown',
      'Monitoring integration pending',
      Icons.folder_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final operational = _services
        .where((s) => s.status == 'Operational')
        .length;

    final degraded = _services
        .where((s) => s.status == 'Degraded')
        .length;

    final unknown = _services
        .where((s) => s.status == 'Unknown')
        .length;

    final filtered = _services.where(
      (service) =>
          _selectedFilter == 'All' ||
          service.status == _selectedFilter,
    ).toList();

    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 1260),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KAISA / LGU ADMINISTRATION / IT',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'System Health',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 29,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Monitor platform availability, '
                    'service status, and system diagnostics.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _notice(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth >= 700
                              ? 3
                              : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth -
                              gap * (columns - 1)) / columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _stat(
                            'Demo Operational',
                            '$operational',
                            Icons.check_circle_outline,
                            width,
                          ),
                          _stat(
                            'Demo Degraded',
                            '$degraded',
                            Icons.warning_amber_rounded,
                            width,
                          ),
                          _stat(
                            'Unknown',
                            '$unknown',
                            Icons.help_outline_rounded,
                            width,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 27),
                  _servicePanel(filtered),
                  const SizedBox(height: 25),
                  _monitoringNote(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8DE),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFFF1E3A7),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF92650D),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'DEVELOPMENT PREVIEW — All service statuses '
                'below are fictional. This page does not '
                'check Supabase uptime or production health.',
                style: TextStyle(
                  color: Color(0xFF73550E),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _stat(
    String label,
    String count,
    IconData icon,
    double width,
  ) =>
      Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: _surface(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _green, size: 27),
            const SizedBox(height: 17),
            Text(
              count,
              style: const TextStyle(
                color: _forest,
                fontWeight: FontWeight.w900,
                fontSize: 29,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  Widget _servicePanel(List<_DemoService> services) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Monitoring',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Example services and their sample status.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filter by status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                    value: 'All', child: Text('All')),
                DropdownMenuItem(
                    value: 'Operational',
                    child: Text('Operational')),
                DropdownMenuItem(
                    value: 'Degraded',
                    child: Text('Degraded')),
                DropdownMenuItem(
                    value: 'Unknown',
                    child: Text('Unknown')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFilter = value);
                }
              },
            ),
          ),
          const SizedBox(height: 18),
          if (services.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No services match this filter.',
                style: TextStyle(color: _muted),
              ),
            )
          else
            for (final service in services) ...[
              _serviceRow(service),
              const Divider(height: 23, color: _stroke),
            ],
        ],
      ),
    );
  }

  Widget _serviceRow(_DemoService service) {
    final Color statusColor;

    switch (service.status) {
      case 'Operational':
        statusColor = _green;
        break;
      case 'Degraded':
        statusColor = const Color(0xFF94650D);
        break;
      default:
        statusColor = _muted;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            service.icon,
            color: _forest,
            size: 23,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service.description,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            service.status,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _monitoringNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Production Monitoring Requirements',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 13),
          Text(
            'Before deployment, integrate authorized '
            'monitoring for API availability, errors, '
            'latency, database health, and backup status. '
            'Sensitive infrastructure diagnostics must '
            'be retrieved from trusted backend services.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.circle,
                color: _gold,
                size: 11,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monitoring integration: Not configured',
                  style: TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _surface() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _stroke),
      );
}

class _DemoService {
  final String name;
  final String category;
  final String status;
  final String description;
  final IconData icon;

  const _DemoService(
    this.name,
    this.category,
    this.status,
    this.description,
    this.icon,
  );
}
