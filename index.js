// set up handler for local ini file config
const fs = require('fs');
const ini = require('ini');
let localconfig = {
    host: 'host',
    db_name: 'guest',
    db_user: 'Cyril',
    db_pw: 'guest'
};
localconfig = ini.parse(fs.readFileSync('db.ini', 'utf-8'));

// MySQL
const mysql = require("mysql");

// Set up hardware process for GPIO
const SerialPort = require('serialport').SerialPort;

// Set up hardware keypress handler (An entry ASCII character on a mag card is treated the same as a key press).
let stdin = process.stdin;
stdin.setRawMode(true);
stdin.resume();
stdin.setEncoding('utf8');
console.log("Await Input");
stdin.on('data', function( key){
    if(key === '\u0003'){
        //By creating a listener, the default is overridden so the Control-C exit command must still exist.
        //A card made by the University will never have this.
        //TODO: make a fix for security reasons and accidental halt interpretation without restart
        console.log("Exit");
        process.exit();
    }else{
        //process.stdout.write(key);
        cardListener.getDigit(key);
    }
});

//This lists all paths of viable serial ports.
//SerialPort.list().then(ports => {
//    console.log("list");
//    ports.forEach(function(port) {
//        console.log(port.path)
//    })
//});

// Note: This will vary from test to production hosts
const serial_port = 'COM6';

let portObj;
portObj = new SerialPort({
    path: serial_port,
    baudRate: 9600,
    // port is to only be open when in use. Otherwise, error handling becomes a mess.
    autoOpen: false
});

portObj.open(function(error){
    if(error){
        serialCommError(error)
    }else{
        console.log("Serial Port Opened Successfully");

        portObj.on('error', function(data) {
            serialCommError(data);
        });
    }
});

function sendSerialCommand(commandString){
    if(commandString[commandString.length - 1] !== '\u000d'){
        commandString += '\u000d';
    }
    portObj.write(commandString, function(err){
        if(err){
            serialCommError(err);
        }
    });
}

function serialCommError(err){
    console.log("Serial Communications Error: " + err);
}

// Add event listener to incoming data
portObj.on('data', function(data) {
    // get buffered data and parse it to an utf-8 string
    data = data.toString("UTF-8");
    // you could for example, send this data now to the client via socket.io
    // io.emit('emit_data', data);
    let dataArray = data.split("\u000a\u000d");
    console.log("DEVICE IO");
    console.log("--------------------");
    console.log(dataArray);
    console.log("--------------------");
    if(dataArray.length === 1){
        if(dataArray === ["\u003e"]){
            console.log("Delayed Reply From Successful Execution of Command");
        }else {
            serialCommError("Command Send with no reply (check syntax)");
        }
    }
    if(dataArray.length === 2){
        if(dataArray[1] === "\u003e"){
            console.log("Success");
        }else {
            serialCommError("Command Executed Successfully. Device Readiness not read in response buffer (flush then try again)");
        }
    }
    if(dataArray.length === 3){
        console.log("Success");
    }
});

sendSerialCommand("ver\u000d");
//Also
//sendSerialCommand("ver\r");

/*
IMPORTANT!
PortObj.data records all I/O!
sendSerialCommand("ver\u000d");

Output Meaning
76 65 72 0a 0d 41 30 4d 31 30 2e 30 31 0a 0d 3e
v  e  r  NL CR A  0  M  1  0  .  0  1  NL CR >

ver : sent
A0M10.01 : received
> : ready

*/


//create card listener:
const cardListener = {
    cardNumber : "",
    cardLength: 9,
    readState: false,
    readStateTimeout: 500,
    timeout: null,
    getDigit: function(digit){
        if(parseInt(digit) >= 0 && parseInt(digit) <= this.cardLength ){
            if(this.cardNumber.length < this.cardLength){
                this.cardNumber += digit;
                this.read(); //lets timer know we're reading something
            }
            if(this.cardNumber.length === this.cardLength){
                console.log("Successful Read: " + this.cardNumber);
                dbHandler.verifyCard(this.cardNumber);
                this.endReader();
            }
        }
    },
    endReader: function(){
        this.cardNumber = "";
        this.readState = false;
        this.timeout = null;
    },
    read: function(){
        // this is to keep buffer clean in case of accidental partial or misreads
        this.readState = true;
        clearTimeout(this.timeout);
        this.timeout = null;
        this.timeout = setTimeout(function(){
            //parent object is not automatically passed to scope of setTimeout function
            cardListener.endReader();
        }, this.readStateTimeout);
    },
    isReading: function(){
        return this.readState;
    }
};

//create database handler
const dbHandler = {
    mysql : mysql,
    connection : mysql.createConnection({
        host: localconfig.host,
        user: localconfig.db_user,
        password: localconfig.db_pw,
        database: localconfig.db_name
    }),
    connect: function(){
        this.connection.connect(function(error){
            if(error){
                databaseError(error);
            }else{
                console.log("Database Connection Successful!")
            }
        })
    },
    verifyCard: function(card){
        let sql="Select bid, active_state from allowed_entry where bid = " + card + ";"
        this.connection.query(sql, [true], (error, results, fields) => {
            if(error){
                console.log(error);
            }
            if(results){
                console.log(results);
            }
        });
        /*
        * Returns-
        * If Found : [ RowDataPacket { bid: 900013663, active_state: '1' } ]
        * If Not : []
        * */
    }
};

dbHandler.connect();


function databaseError(error){
    console.log("Database Error: " + error);
}

sendSerialCommand('gpio clear 6');
