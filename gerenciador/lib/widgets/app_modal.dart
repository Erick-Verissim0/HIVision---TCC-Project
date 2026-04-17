import 'dart:ui';

import 'package:flutter/material.dart';

Future<T?> showAppModal<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'app-modal',
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      final screen = MediaQuery.sizeOf(context);

      return Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: const Color.fromRGBO(54, 23, 18, 0.26),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 980,
                    maxHeight: screen.height * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFEFD8CF)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(58, 16, 11, 0.22),
                        blurRadius: 38,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFFDFB), Color(0xFFFFF6F0)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF1DDD5)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 4,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8CBC0),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    color: Color(0xFF5C1711),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1EA),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFFEFD2C8)),
                                ),
                                child: IconButton(
                                  tooltip: 'Fechar',
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color(0xFF7A251D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF8F5),
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF1DDD5)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preencha os campos obrigatórios e complete os dados clínicos conforme necessário.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7D6A64),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7D6A64),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(
                                        color: Color(0xFFD32F2F),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    TextSpan(text: ' indica campo obrigatório'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, modalChild) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: modalChild,
        ),
      );
    },
  );
}
