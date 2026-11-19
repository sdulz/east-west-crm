import 'package:flutter/material.dart';
import 'package:field_crm/common/widgets/detail_row.dart';


class DetailsColumnRow extends StatelessWidget {
  final String rightTitle;
  final String rightValue;
  final String leftTitle;
  final String leftValue;
  

  const DetailsColumnRow({
    super.key,
    required this.rightTitle,
    required this.rightValue,
    required this.leftTitle,
    required this.leftValue,
  
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: DetailsColumn(
           
            heading: leftTitle,
            value: leftValue,
          ),
        ),
        Expanded(
          child: DetailsColumn.right(
           
            heading: rightTitle,
            value: rightValue,
          ),
        ),
      ],
    );
  }
}
