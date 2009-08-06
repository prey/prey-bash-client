if (WScript.Arguments.length < 1) {
    msg = "No message supplied"
}
else {
  msg = "";
  for (i = 0; i < WScript.Arguments.length; i++) {
      msg = msg + WScript.Arguments.Item(i) + " ";
  }
}
WScript.Echo(msg);
