import 'dart:async';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_amplify/add_todo_form.dart';
import 'package:flutter_amplify/models/ModelProvider.dart';
import 'package:flutter_amplify/not_logged_in_page.dart';
import 'package:flutter_amplify/todos_list.dart';
import 'amplifyconfiguration.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({Key? key}) : super(key: key);

  @override
  _TodosPageState createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  // loading ui state - initially set to a loading state
  bool _isLoading = true;

  // list of Todos - initially empty
  List<Todo> _todos = [];

  // amplify plugins
  final AmplifyDataStore _dataStorePlugin =
  AmplifyDataStore(modelProvider: ModelProvider.instance);
  final AmplifyAPI _apiPlugin = AmplifyAPI();
  final AmplifyAuthCognito _authPlugin = AmplifyAuthCognito();

  // subscription of Todo QuerySnapshots - to be initialized at runtime
  late StreamSubscription<QuerySnapshot<Todo>> _subscription;

  AuthSession? _authSession;

  @override
  void initState() {

    // kick off app initialization
    _initializeApp();

    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();

    super.dispose();
  }

  Future<void> _initializeApp() async {
    // configure Amplify
    await _configureAmplify();

    // Query and Observe updates to Todo models. DataStore.observeQuery() will
    // emit an initial QuerySnapshot with a list of Todo models in the local store,
    // and will emit subsequent snapshots as updates are made
    //
    // each time a snapshot is received, the following will happen:
    // _isLoading is set to false if it is not already false
    // _todos is set to the value in the latest snapshot
    _subscription = Amplify.DataStore.observeQuery(Todo.classType)
        .listen((QuerySnapshot<Todo> snapshot) {
      setState(() {
        if (_isLoading) _isLoading = false;
        _todos = snapshot.items;
      });
    });

    Amplify.Auth.streamController.stream.listen((event) async {
      final result = await Amplify.Auth.fetchAuthSession();
      setState(() {
        _authSession = result;
      });
    });
    final result = await Amplify.Auth.fetchAuthSession();
    setState(() {
      _authSession = result;
    });
  }

  Future<void> _configureAmplify() async {
    try {

      // add Amplify plugins
      await Amplify.addPlugins([_dataStorePlugin, _apiPlugin, _authPlugin]);

      // configure Amplify
      //
      // note that Amplify cannot be configured more than once!
      await Amplify.configure(amplifyconfig);
    } catch (e) {

      // error handling can be improved for sure!
      // but this will be sufficient for the purposes of this tutorial
      if (kDebugMode) {
        print('An error occurred while configuring Amplify: $e');
      }
    }
  }

  Widget _mainWidget(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!(_authSession?.isSignedIn ?? false)) {
      return const NotLoggedInPage();
    }

    return TodosList(todos: _todos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todo List'),
        actions: [
          !(_authSession?.isSignedIn ?? false)
              ? Container()
              : IconButton(
            onPressed: () {
              Amplify.Auth.signOut();
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: _mainWidget(context),
      floatingActionButton: !(_authSession?.isSignedIn ?? false)
          ? null
          : FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTodoForm()),
          );
        },
        tooltip: 'Add Todo',
        label: Row(
          children: const [Icon(Icons.add), Text('Add todo')],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}