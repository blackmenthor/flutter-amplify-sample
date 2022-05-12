import 'package:flutter/material.dart';
import 'package:flutter_amplify/models/Todo.dart';
import 'package:flutter_amplify/models/ModelProvider.dart';
import 'package:flutter_amplify/todo_item.dart';

class TodosList extends StatelessWidget {
  final List<Todo> todos;

  const TodosList({Key? key, required this.todos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return todos.isNotEmpty
        ? ListView(
        padding: const EdgeInsets.all(8),
        children: todos.map((todo) => TodoItem(todo: todo)).toList())
        : const Center(child: Text('Tap button below to add a todo!'));
  }
}