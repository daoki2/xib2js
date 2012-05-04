/**
 * XIB to JavaSript Application for Titanium Mobile
 * @author Copyright (c) 2010-2012 daoki2
 * @version 2.0.0
 * 
 * Copyright (c) 2010-2012 daoki2
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import flash.desktop.Clipboard;
import flash.desktop.ClipboardFormats;
import flash.desktop.NativeDragManager;
import flash.desktop.NativeProcess;
import flash.events.*;
import flash.filesystem.*;
import flash.net.ServerSocket;
import mx.controls.*;
import mx.events.*;
import mx.collections.ArrayCollection;
import org.libspark.utils.FileUtil;
import org.libspark.utils.PreferenceUtil;

private var saveBtn:Button;
private var syncBtn:Button;
private var prefFile:String = "preference.xml";
//public var checkVersion:CheckBox = new CheckBox();

private var process:NativeProcess = new NativeProcess();
private var serverSocket:ServerSocket = new ServerSocket();
private var clientSocket:ArrayCollection = new ArrayCollection();

/**
 * Initialize the application
 */
private function init():void {

    setupBonjourService();

    //checkVersion.selected = true;
    var result:Object = PreferenceUtil.load(this, prefFile);
    if (!result.status) {
	trace(result.message);
	this.visible = true;
    }

    horizontalScrollPolicy = "off";
    verticalScrollPolicy = "off";

    addEventListener(Event.CLOSING, app_closingHandler);
    addEventListener(ResizeEvent.RESIZE, app_resizeHandler);
    addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, nativeDragEnterHandler);
    addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, nativeDragDropHandler);

    saveBtn= new Button();
    saveBtn.label = "Save";
    saveBtn.x = 8;
    saveBtn.y = 16;
    saveBtn.width = 56;
    saveBtn.height = 28;
    saveBtn.addEventListener(MouseEvent.CLICK, saveBtn_clickHandler);
    saveBtn.enabled = false;
    toolBar.addChild(saveBtn);

    syncBtn= new Button();
    syncBtn.label = "Sync";
    syncBtn.x = 70;
    syncBtn.y = 16;
    syncBtn.width = 56;
    syncBtn.height = 28;
    syncBtn.addEventListener(MouseEvent.CLICK, syncBtn_clickHandler);
    syncBtn.enabled = false;
    toolBar.addChild(syncBtn);

    /*
    checkVersion.label = "Check .xib version";
    checkVersion.x = width - 144;
    checkVersion.y = 22;
    addChild(checkVersion);
    */
    app_resizeHandler(null);
    visible = true;
}

/**
 * Startup bounjour service
 */
private function setupBonjourService():void {
    var args:Vector.<String> = new Vector.<String>();
    args.push("-R");
    args.push("TiMock Service");
    args.push("_timock._tcp");
    args.push("");
    args.push("40401");

    var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
    info.executable = new File("/usr/bin/dns-sd");
    info.arguments = args;

    process.start(info);
    process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onStartupService);
}

private function onStartupService(event:ProgressEvent):void{
    var stdo:IDataInput = process.standardOutput;

    var result:Array = [{code: stdo.readUTFBytes(stdo.bytesAvailable).toString()}];

    // bind socket
    if (!serverSocket.bound) {
	try {
	    serverSocket.bind(40401);
	    serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, onConnect);
	    serverSocket.listen();
	} catch (e:IOError) {
	    createTabs([{code: "#Error: Please close all client and restart xib2js"}]);
	}
    }
}

private function onConnect(e:ServerSocketConnectEvent):void {
    var client:Socket = e.socket;
    client.addEventListener(ProgressEvent.SOCKET_DATA, onClientSocketData);
    clientSocket.addItem(client);
}

private function onClientSocketData(e:ProgressEvent):void {
    var buffer:ByteArray = new ByteArray();
    e.target.readBytes(buffer, 0, e.target.bytesAvailable - 2);
    var result:Array = [{code: buffer.toString()}];

    switch(buffer.toString()) {
    case "Connected":
	//createTabs(result);
	syncBtn.enabled = true;
	break;
    case "file":
	e.target.writeBytes(copyFile.data);
	break;
    default:
	Alert.show("Unknown command: '" + buffer.toString() + "'", "ERROR");
	break;
    }

    e.target.readBytes(buffer, 0, e.target.bytesAvailable); // read remain    
}

/**
 * Copy file to mobile device
 */
private var copyFile:File;
private function copy(file:File):void {
    copyFile = file;
    copyFile.addEventListener(Event.COMPLETE, onFileLoaded);
    copyFile.load();
}

private function onFileLoaded(e:Event):void {
    copyFile.removeEventListener(Event.COMPLETE, onFileLoaded);
    for each (var _socket:Socket in clientSocket) {
	_socket.writeUTFBytes("file:" + e.target.name); // send filename to mobile device 
    }
}

/**
 * Parse the .xib file and generate the JavsScript code
 */
private function parse(file:File):void {
    XibParser.cleanup();
    JsCodegen.cleanup();
    trace("------------------ start parsing ----------------------");
    XibParser.exec(file, /*checkVersion.selected*/ false);
    var _parsedData:Array = XibParser.getParsedData();
    trace("--------------- start code generater ------------------");
    if (_parsedData.length > 0) {
	JsCodegen.exec(_parsedData);
	createTabs(JsCodegen.getGeneratedCode());
	saveBtn.enabled = true;
    }
}

/*
 * Application close handler
 */
private function app_closingHandler(event:Event):void {
    if (process.running) {
	process.exit();
    }

    if (serverSocket.bound) {
	serverSocket.close();
    }

    if (clientSocket.length != 0) {
	for each(var _socket:Socket in clientSocket) {
	    if (_socket.connected) {
	        _socket.close();
	    }
	}
    }

    var prefList:ArrayCollection = new ArrayCollection();
    prefList.addItem("nativeWindow.x");
    prefList.addItem("nativeWindow.y");
    prefList.addItem("width");
    prefList.addItem("height");
    //prefList.addItem("checkVersion.selected");
    PreferenceUtil.save(this, prefList, prefFile);
}

/*
 * Application resize handler
 */
private function app_resizeHandler(event:ResizeEvent):void {
    toolBar.width = width;
    //checkVersion.x = width - 144;
    tabs.width = width - 20;
    tabs.height = height - 84;
    
    var _text:TextArea;
    var children:Array = tabs.getChildren();
    for each (var child:Canvas in children) {
	child.width = width - 16;
	child.height = height - 120;
	_text = TextArea(child.getChildAt(0));
	_text.width = child.width - 8;
	_text.height = child.height - 8;
    }
}

/**
 * Native DragEnter handler
 */
private function nativeDragEnterHandler(event:NativeDragEvent):void {
    var clipboard:Clipboard = event.clipboard;
    switch(String(clipboard.formats[0])) {
    case ClipboardFormats.FILE_LIST_FORMAT:
	NativeDragManager.acceptDragDrop(InteractiveObject(event.currentTarget));
	break;
    default:
	trace(String(clipboard.formats),"is not allowed to drop");
	break;
    }
}

/**
 * Native DragDrop handler
 */
private function nativeDragDropHandler(event:NativeDragEvent):void {
    var clipboard:Clipboard = event.clipboard;
    var files:Object = clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
    if (files[0].extension == "xib") {
	saveBtn.enabled = false;
	callLater(parse, [files[0]]);
    } else {
	callLater(copy, [files[0]]);
    }
}

/**
 * Select Directory to save the files
 */
private function saveBtn_clickHandler(event:MouseEvent):void {
    var dir:File = File.documentsDirectory;
    try {
	dir.browseForDirectory("Select folder to save");
	dir.addEventListener(Event.SELECT, dirSelectHandler);
    } catch (err:Error) {
	Alert.show(err.message, "ERROR");
    }
}

private function syncBtn_clickHandler(event:MouseEvent):void {
    var children:Array = tabs.getChildren();
    var code:String = "";
    for each (var child:Canvas in children) {
	var textarea:TextArea = TextArea(child.getChildAt(0));
	code += build_txt(textarea.text) + "\n";
    }
    code += "}());\n";
    //createTabs([{code: code}]);
    for each (var _socket:Socket in clientSocket) {
	_socket.writeUTFBytes("code:" + code);
    }
}

private function build_txt(code:String):String {
    var result:String = "";
    
    var line:Array = code.split("\r");
    for (var i:int = 0; i < line.length; i++) {
	if (line[i].search("require") == -1 && line[i].search("module.exports") == -1 ) {
	    if (line[i] != "}());") {
		result += String(line[i]) + "\n";
	    }
	}   
    }
    return result;
}

/**
 * Save JavaScript codes
 */
private function dirSelectHandler(e:Event):void {
    var dir:File = e.target as File;
    trace("Prj Dir:", dir.nativePath);
    trace(dir.name);
    var children:Array = tabs.getChildren();
    var _file:File = new File();
    var _fs:FileStream = new FileStream();
    for each (var child:* in children) {
	_file = _file.resolvePath(dir.nativePath + "/" + child.label);
	_fs.open(_file, FileMode.WRITE);
	_fs.writeUTFBytes(TextArea(child.getChildAt(0)).text);
	_fs.close();
    }
    Alert.show("JavaScript files created", "CONFIRM");
}

/**
 * Create tabs for each JavaScript codes
 */
private function createTabs(scripts:Array):void {
    tabs.removeAllChildren();
    for each (var script:* in scripts) {
	var tab:Canvas = new Canvas();
	tab.width = width - 16;
	tab.height = height - 100;
	tab.label = script.name;
	tab.horizontalScrollPolicy = "off";
	tab.verticalScrollPolicy = "off";
	var codearea:TextArea = new TextArea();
	codearea.x = codearea.y = 4;
	codearea.width = tab.width - 8;
	codearea.height = tab.height - 24;
	codearea.text = script.code;
	tab.addChild(codearea);
	tabs.addChild(tab);
    }
}
