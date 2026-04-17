import 'package:flutter/material.dart';

import '../models/pagination.dart';
import 'app_button.dart';

class PaginatedControls extends StatefulWidget {
  final PaginationMeta pagination;
  final ValueChanged<int> onPageChange;

  const PaginatedControls({
    super.key,
    required this.pagination,
    required this.onPageChange,
  });

  @override
  State<PaginatedControls> createState() => _PaginatedControlsState();
}

class _PaginatedControlsState extends State<PaginatedControls> {
  late final TextEditingController _jumpController;

  @override
  void initState() {
    super.initState();
    _jumpController = TextEditingController(text: '${widget.pagination.page}');
  }

  @override
  void didUpdateWidget(covariant PaginatedControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pagination.page != oldWidget.pagination.page) {
      _jumpController.text = '${widget.pagination.page}';
    }
  }

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecione a página'),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _jumpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Página'),
              ),
            ),
            const SizedBox(width: 10),
            AppButton(
              title: 'Ir',
              round: true,
              onPressed: () {
                final parsed = int.tryParse(_jumpController.text);
                if (parsed == null) {
                  return;
                }
                final target = parsed.clamp(1, widget.pagination.totalPages);
                widget.onPageChange(target);
              },
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Página ${widget.pagination.page} de ${widget.pagination.totalPages}'),
            const SizedBox(width: 10),
            AppButton(
              title: 'Anterior',
              round: true,
              disabled: widget.pagination.firstPage,
              onPressed: () => widget.onPageChange(widget.pagination.page - 1),
            ),
            const SizedBox(width: 10),
            AppButton(
              title: 'Próximo',
              round: true,
              disabled: widget.pagination.lastPage,
              onPressed: () => widget.onPageChange(widget.pagination.page + 1),
            ),
          ],
        ),
      ],
    );
  }
}
