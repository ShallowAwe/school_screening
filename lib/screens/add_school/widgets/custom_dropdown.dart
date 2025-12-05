import 'package:flutter/material.dart';

/// Generic reusable dropdown widget
class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) getLabel;
  final void Function(T?) onChanged;
  final String hint;
  final bool isLoading;

  const CustomDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.getLabel,
    required this.onChanged,
    required this.hint,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: isLoading
          ? Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading...', style: TextStyle(color: Colors.grey[600])),
              ],
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                hint: Text(hint, style: TextStyle(color: Colors.grey[500])),
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(getLabel(item), style: TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: items.isEmpty ? null : onChanged,
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
              ),
            ),
    );
  }
}
