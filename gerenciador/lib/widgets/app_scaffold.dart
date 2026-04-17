import 'package:flutter/material.dart';

import '../utils/responsive.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget menu;
  final Widget body;

  const AppScaffold({
    super.key,
    required this.title,
    required this.menu,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      drawer: isMobile ? Drawer(child: SafeArea(child: menu)) : null,
      body: Row(
        children: [
          if (!isMobile) SizedBox(width: 320, child: menu),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF9F6), Color(0xFFF8F6F4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFEDD7CE)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F140F),
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFEDD7CE)),
                      ),
                      child: body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
