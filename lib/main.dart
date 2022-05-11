// dart async library we will refer to when setting up real time updates
import 'dart:async';
// flutter and ui libraries
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter/material.dart';
// amplify packages we will need to use
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// amplify configuration and models that should have been generated for you
import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';
import 'models/Todo.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amplified Todo',
      home: TodosPage(),
    );
  }
}

class TodosPage extends StatefulWidget {
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
      print('An error occurred while configuring Amplify: $e');
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
            MaterialPageRoute(builder: (context) => AddTodoForm()),
          );
        },
        tooltip: 'Add Todo',
        label: Row(
          children: [Icon(Icons.add), Text('Add todo')],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class NotLoggedInPage extends StatefulWidget {
  const NotLoggedInPage({Key? key}) : super(key: key);

  @override
  State<NotLoggedInPage> createState() => _NotLoggedInPageState();
}

class _NotLoggedInPageState extends State<NotLoggedInPage> {
  String? _email;
  String? _password;
  String? _name;
  String? _verificationCode;

  bool _login = true;
  bool _inputVerificationCode = false;

  Widget _loginWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Login to your account',),
        const SizedBox(
          height: 16.0,
        ),
        if (_inputVerificationCode) ...[
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Verification Code',
            ),
            keyboardType: TextInputType.number,
            onChanged: (code) {
              setState(() {
                _verificationCode = code;
              });
            },
          ),
          const SizedBox(
            height: 16.0,
          ),
          MaterialButton(
            child: Text('Verify'),
            color: Colors.blue,
            textColor: Colors.white,
            onPressed: () async {
              try {
                await Amplify.Auth.confirmSignUp(
                  username: _email!,
                  confirmationCode: _verificationCode!,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Verification Success! Please login to your account!'),
                ));
                setState(() {
                  _inputVerificationCode = false;
                });
              } catch (ex) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ex.toString()),
                ));
              }
            },
          ),
        ] else ...[
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Email',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (email) {
              setState(() {
                _email = email;
              });
            },
          ),
          const SizedBox(
            height: 8.0,
          ),
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            ),
            keyboardType: TextInputType.text,
            obscureText: true,
            onChanged: (pass) {
              setState(() {
                _password = pass;
              });
            },
          ),
          const SizedBox(
            height: 16.0,
          ),
          MaterialButton(
            child: Text('Login'),
            color: Colors.blue,
            textColor: Colors.white,
            onPressed: () async {
              try {
                await Amplify.Auth.signIn(
                  username: _email!,
                  password: _password!,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Sign In Success!'),
                ));
              } on UserNotConfirmedException catch (ex) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('You need to confirm your account first!'),
                ));
                await Amplify.Auth.resendSignUpCode(username: _email!);
                setState(() {
                  _inputVerificationCode = true;
                });
              } catch (ex) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ex.toString()),
                ));
              }
            },
          ),
        ],
        const SizedBox(
          height: 16.0,
        ),
        InkWell(
          onTap: () {
            setState(() {
              _login = false;
            });
          },
          child: const Text(
            'or, sign up instead?',
          ),
        ),
      ],
    );
  }

  Widget _signupWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Sign up to our services',),
        const SizedBox(
          height: 16.0,
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Email',
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (email) {
            setState(() {
              _email = email;
            });
          },
        ),
        const SizedBox(
          height: 8.0,
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Name',
          ),
          keyboardType: TextInputType.name,
          onChanged: (name) {
            setState(() {
              _name = name;
            });
          },
        ),
        const SizedBox(
          height: 8.0,
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Password',
          ),
          keyboardType: TextInputType.text,
          obscureText: true,
          onChanged: (pass) {
            setState(() {
              _password = pass;
            });
          },
        ),
        const SizedBox(
          height: 16.0,
        ),
        MaterialButton(
          child: Text('Sign Up'),
          color: Colors.blue,
          textColor: Colors.white,
          onPressed: () async {
            try {
              Map<CognitoUserAttributeKey, String> userAttributes = {
                CognitoUserAttributeKey.email: _email!,
                CognitoUserAttributeKey.name: _name!,
                // additional attributes as needed
              };
              await Amplify.Auth.signUp(
                username: _email!,
                password: _password!,
                options: CognitoSignUpOptions(
                  userAttributes: userAttributes,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Sign Up Success! Please confirm your code'),
              ));
              setState(() {
                _login = true;
                _inputVerificationCode = true;
              });
            } catch (ex) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ex.toString()),
              ));
            }
          },
        ),
        const SizedBox(
          height: 16.0,
        ),
        InkWell(
          onTap: () {
            setState(() {
              _login = true;
            });
          },
          child: const Text(
            'or, login instead?',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: _login
            ? _loginWidget(context)
            : _signupWidget(context),
      ),
    );
  }
}


class TodosList extends StatelessWidget {
  final List<Todo> todos;

  TodosList({required this.todos});

  @override
  Widget build(BuildContext context) {
    return todos.length >= 1
        ? ListView(
        padding: EdgeInsets.all(8),
        children: todos.map((todo) => TodoItem(todo: todo)).toList())
        : Center(child: Text('Tap button below to add a todo!'));
  }
}

class TodoItem extends StatelessWidget {
  final double iconSize = 24.0;
  final Todo todo;

  TodoItem({required this.todo});

  void _deleteTodo(BuildContext context) async {
    try {
      // to delete data from DataStore, we pass the model instance to
      // Amplify.DataStore.delete()
      await Amplify.DataStore.delete(todo);
    } catch (e) {
      print('An error occurred while deleting Todo: $e');
    }
  }

  Future<void> _toggleIsComplete() async {

    // copy the Todo we wish to update, but with updated properties
    Todo updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
    try {

      // to update data in DataStore, we again pass an instance of a model to
      // Amplify.DataStore.save()
      await Amplify.DataStore.save(updatedTodo);
    } catch (e) {
      print('An error occurred while saving Todo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          _toggleIsComplete();
        },
        onLongPress: () {
          _deleteTodo(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(todo.name,
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(todo.description ?? 'No description'),
                ],
              ),
            ),
            Icon(
                todo.isCompleted
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: iconSize),
          ]),
        ),
      ),
    );
  }
}

class AddTodoForm extends StatefulWidget {
  @override
  _AddTodoFormState createState() => _AddTodoFormState();
}

class _AddTodoFormState extends State<AddTodoForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future<void> _saveTodo() async {

    // get the current text field contents
    String name = _nameController.text;
    String description = _descriptionController.text;

    // create a new Todo from the form values
    // `isComplete` is also required, but should start false in a new Todo
    Todo newTodo = Todo(
        name: name,
        description: description.isNotEmpty ? description : null,
        isCompleted: false);

    try {
      // to write data to DataStore, we simply pass an instance of a model to
      // Amplify.DataStore.save()
      await Amplify.DataStore.save(newTodo);

      // after creating a new Todo, close the form
      Navigator.of(context).pop();
    } catch (e) {
      print('An error occurred while saving Todo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Todo'),
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(filled: true, labelText: 'Name')),
              TextFormField(
                  controller: _descriptionController,
                  decoration:
                  InputDecoration(filled: true, labelText: 'Description')),
              ElevatedButton(onPressed: _saveTodo, child: Text('Save'))
            ],
          ),
        ),
      ),
    );
  }
}