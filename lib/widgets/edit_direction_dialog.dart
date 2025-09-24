import 'package:flutter/material.dart';
import 'package:wheres_my_bus/services/custom_direction_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class EditDirectionDialog extends StatefulWidget {
  final String naptanAtco;
  final String currentDirection;
  final String originalDirection;

  const EditDirectionDialog({
    super.key,
    required this.naptanAtco,
    required this.currentDirection,
    required this.originalDirection,
  });

  @override
  State<EditDirectionDialog> createState() => _EditDirectionDialogState();
}

class _EditDirectionDialogState extends State<EditDirectionDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentDirection);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveDirection() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newDirection = _controller.text.trim();
      await CustomDirectionService.saveCustomDirection(widget.naptanAtco, newDirection);
      
      if (mounted) {
        Navigator.of(context).pop(newDirection.isEmpty ? widget.originalDirection : newDirection);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving direction: $e'),
            backgroundColor: AppColors.londonRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Direction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize the direction label for this bus stop:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Direction',
              hintText: widget.originalDirection,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              helperText: 'Leave empty to use original direction',
            ),
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          Text(
            'Original: ${widget.originalDirection}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDirection,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.londonRed,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
