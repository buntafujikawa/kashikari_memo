import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share/share.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'かしかりメモ',
      routes: <String, WidgetBuilder>{
        '/': (_) => Splash(),
        '/list': (_) => List(),
      },
    );
  }
}

User? firebaseUser;
final FirebaseAuth _auth = FirebaseAuth.instance;

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _getUser(context);
    return const Scaffold(
      body: Center(
        child: const Text('スプラッシュ画面'),
      ),
    );
  }
}

void _getUser(BuildContext context) async {
  try {
    firebaseUser = await _auth.currentUser;
    if (firebaseUser == null) {
      await _auth.signInAnonymously();
      firebaseUser = await _auth.currentUser;
    }

    Navigator.pushReplacementNamed(context, '/list');
  } catch (e) {
    Fluttertoast.showToast(msg: 'Firebaseとの接続に失敗しました');
  }
}

class InputForm extends StatefulWidget {
  const InputForm(this.document);
  final DocumentSnapshot? document;

  @override
  _MyInputFormState createState() => _MyInputFormState();
}

class _FormData {
  String borrowOrLend = 'borrow';
  String user = '';
  String stuff = '';
  DateTime date = DateTime.now();
}

class _MyInputFormState extends State<InputForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();

  Future<DateTime?> _selectTime(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: _data.date,
      firstDate: DateTime(_data.date.year - 2),
      lastDate: DateTime(_data.date.year + 2),
    );
  }

  void _setLendOrRent(String value) {
    setState(() {
      _data.borrowOrLend = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference _mainReference;
    _mainReference = FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser?.uid)
        .collection('transaction')
        .doc();

    bool deleteFlg = false;

    if (widget.document != null) {
      if (_data.user == '' && _data.stuff == '') {
        _data.borrowOrLend = widget.document!['borrowOrLend'] as String;
        _data.user = widget.document!['user'] as String;
        _data.stuff = widget.document!['stuff'] as String;
        _data.date = widget.document!['date'].toDate() as DateTime;
      }

      _mainReference = FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser?.uid)
          .collection('transaction')
          .doc(widget.document!.id);

      deleteFlg = true;
    }

    return Scaffold(
        appBar: AppBar(title: const Text('かしかり入力'), actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                print('保存ボタンを押しました');
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _mainReference.set({
                    'borrowOrLend': _data.borrowOrLend,
                    'user': _data.user,
                    'stuff': _data.stuff,
                    'date': _data.date,
                  });
                  Navigator.pop(context);
                }
              }),
          IconButton(
              icon: const Icon(Icons.delete),
              onPressed: !deleteFlg
                  ? null
                  : () {
                      print('削除ボタンを押しました');
                      _mainReference.delete();
                      Navigator.pop(context);
                    }),
          IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Share.share(
                      "【${_data.borrowOrLend == 'lend' ? '貸' : '借'} ${_data.stuff}" +
                          "\n期限: ${_data.date.toString().substring(0, 10)}】" +
                          "\n相手: ${_data.user}" +
                          "\n#かしかりメモ");
                }
              }),
        ]),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: <Widget>[
                RadioListTile(
                    value: 'borrow',
                    groupValue: _data.borrowOrLend,
                    title: const Text('借りた'),
                    onChanged: (String? value) {
                      print('借りたをタッチしました');
                      _setLendOrRent(value!);
                    }),
                RadioListTile(
                    value: 'lend',
                    groupValue: _data.borrowOrLend,
                    title: const Text('貸した'),
                    onChanged: (String? value) {
                      print('貸したをタッチしました');
                      _setLendOrRent(value!);
                    }),
                TextFormField(
                  decoration: const InputDecoration(
                      icon: const Icon(Icons.person),
                      hintText: '相手の名前',
                      labelText: 'Name'),
                  onSaved: (String? value) {
                    _data.user = value!;
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return '名前は必須入力項目です';
                    }
                  },
                  initialValue: _data.user,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      icon: const Icon(Icons.business_center),
                      hintText: '借りたもの、貸したもの',
                      labelText: 'loan'),
                  onSaved: (String? value) {
                    _data.stuff = value!;
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return '借りたもの、貸したものは必須入力項目です';
                    }
                  },
                  initialValue: _data.stuff,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child:
                      Text("締め切り日: ${_data.date.toString().substring(0, 10)}"),
                ),
                ElevatedButton(
                    child: const Text('締め切り日変更'),
                    onPressed: () {
                      print('締め切り日変更をタッチしました');
                      _selectTime(context).then((time) {
                        if (time != null && time != _data.date) {
                          setState(() {
                            _data.date = time;
                          });
                        }
                      });
                    })
              ],
            ),
          ),
        ));
  }
}

class List extends StatefulWidget {
  @override
  _MyList createState() => _MyList();
}

class _MyList extends State<List> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('リスト画面'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                print('login');
                showBasicDialog(context);
              }),
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(firebaseUser?.uid)
                  .collection('transaction')
                  .snapshots(),
              // streamに変化があった時に呼び出される
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return const Text('Loading...');
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  padding: const EdgeInsets.only(top: 10.0),
                  itemBuilder: (context, index) =>
                      _buildListItem(context, snapshot.data!.docs[index]),
                );
              })),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          print('新規作成ボタンを押しました');
          Navigator.push(
              context,
              MaterialPageRoute(
                  settings: const RouteSettings(name: '/new'),
                  builder: (BuildContext context) => InputForm(null)));
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return Card(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      ListTile(
        leading: const Icon(Icons.android),
        title: Text(
            "【${document['borrowOrLend'] == "lend" ? "貸" : "借"}】 ${document['stuff']}"),
        subtitle: Text(
            "期限: ${document['date'].toDate().toString().substring(0, 10)}" +
                "\n相手: ${document['user']}"),
      ),
      ButtonBar(children: <Widget>[
        FlatButton(
            child: const Text('編集'),
            onPressed: () {
              print('編集ボタンを押しました');
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      settings: const RouteSettings(name: '/edit'),
                      builder: (BuildContext context) => InputForm(document)));
            })
      ])
    ]));
  }
}

void showBasicDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  var email = '';
  var password = '';

  if (firebaseUser == null || firebaseUser!.isAnonymous) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
                title: Text('ログイン/登録ダイアログ'),
                content: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                          decoration: const InputDecoration(
                              icon: const Icon(Icons.mail), labelText: 'Email'),
                          onSaved: (String? value) {
                            email = value!;
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Emailは必須入力項目です';
                            }
                          }),
                      TextFormField(
                          obscureText: true,
                          decoration: const InputDecoration(
                              icon: const Icon(Icons.vpn_key),
                              labelText: 'Password'),
                          onSaved: (String? value) {
                            password = value!;
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Passwordは必須入力項目です';
                            }
                            if (value.length < 6) {
                              return 'Passwordは6桁以上です';
                            }
                          }),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('キャンセル')),
                  TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _createUser(context, email, password);
                        }
                      },
                      child: const Text('登録')),
                  TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _signIn(context, email, password);
                        }
                      },
                      child: const Text('ログイン')),
                ]));
  } else {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
                title: const Text('確認ダイアログ'),
                content: Text("${firebaseUser!.email}でログインしています"),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('キャンセル')),
                  TextButton(
                      onPressed: () {
                        _auth.signOut();
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (route) => false);
                      },
                      child: const Text('ログアウト')),
                ]));
  }
}

void _signIn(BuildContext context, String email, String password) async {
  try {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  } catch (e) {
    print(e);
    Fluttertoast.showToast(msg: 'FIrebaseのログインに失敗しました');
  }
}

void _createUser(BuildContext context, String email, String password) async {
  try {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  } catch (e) {
    print(e);
    Fluttertoast.showToast(msg: 'FIrebaseの登録に失敗しました');
  }
}
