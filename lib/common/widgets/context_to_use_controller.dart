import 'package:flutter/cupertino.dart';

class ContextToUseController extends InheritedWidget {
  final BuildContext parentContext;

  const ContextToUseController({
    super.key,
    required super.child,
    required this.parentContext,
  });

  static BuildContext contextToUse(BuildContext context){
    final value=context.dependOnInheritedWidgetOfExactType<ContextToUseController>();
    if(value==null)return context;
    return value.parentContext;
  }

  @override
  bool updateShouldNotify(covariant ContextToUseController oldWidget) {
    return oldWidget.parentContext != parentContext;
  }
}
