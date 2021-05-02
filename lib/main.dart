import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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
      home: List(),
    );
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
        title: const Text('リストと画面'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kashikari-memo')
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
            })
      ])
    ]));
  }
}
