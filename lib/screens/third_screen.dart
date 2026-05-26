import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../app.dart';

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Low Eco-Score'),
          content: Text(
            'The product you just scanned has an Eco-Score of E. '
            'Try a more sustainable alternative!',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New badge unlocked: Madrid Verde'),
        backgroundColor: MyApp.ecoGreen,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showToast() {
    Fluttertoast.showToast(
      msg: "+10 XP earned!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: MyApp.ecoGreen,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.share, color: MyApp.ecoGreen),
              title: Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.link, color: MyApp.ecoGreen),
              title: Text('Copy link'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.bookmark, color: MyApp.ecoGreen),
              title: Text('Add to favorites'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications & Actions'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _showAlertDialog(context),
              child: Text('Low Eco-Score alert'),
            ),
            ElevatedButton(
              onPressed: () => _showSnackBar(context),
              child: Text('Badge unlocked (SnackBar)'),
            ),
            ElevatedButton(
              onPressed: _showToast,
              child: Text('+10 XP (Toast)'),
            ),
            ElevatedButton(
              onPressed: () => _showModalBottomSheet(context),
              child: Text('Share (BottomSheet)'),
            ),
          ],
        ),
      ),
    );
  }
}
