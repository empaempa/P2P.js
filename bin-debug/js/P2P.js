/*
* P2P.JS
*
*
*
*/

P2P = (function() {
    "use strict"; "use restrict";
    
    var p2pInstances = {};

    // check SWFObject
    
    if( swfobject === undefined ) {
        console.error( "P2P: SWFObject required. I know, I should AMD this" );
        return;
    }

    
    // constructor
    // parameters:
    // id: name of the p2p instance. used to separate multiple instances
    // display: url to png/jpg/swf to show while connecting 
    // container: div containing the flash
    // callback: function callled when swf has been embedded
    
    function p2p( parameters ) {
        
        this.id = parameters.id;
        this.onSWFEmbeddedCallback = parameters.callback;
        this.swf = undefined;
        this.onCallbacks = {};
        
        p2pInstances[ this.id ] = this;
 
        
        var container = document.createElement( "div" );
        container.id = "P2P_container_" + this.id;
        
        if( parameters.container !== undefined )
            parameters.container.appendChild( container );
        else
            document.body.appendChild( container );
        
        var flashVariables = {};
        var flashParameters = {};
        var flashAttributes = {};
        
        flashVariables.id = this.id;
        flashParameters.quality = "low";
        flashParameters.allowscriptaccess = "always";
        flashAttributes.id = "P2P_swf_" + this.id;
        flashAttributes.name = "P2P_swf_" + this.id;

        var scope = this;
        var method = this.onEmbed;

        swfobject.embedSWF( P2P.swfPath, "P2P_container_" + this.id, "100%", "100%", "10.2", "", flashVariables, flashParameters, flashAttributes, function( result ) {
            method.call( scope, result );
        } );
    }
    
    p2p.prototype.onEmbed = function( result ) {
        
        this.swf = swfobject.getObjectById( "P2P_swf_" + this.id );
        
        if( this.onSWFEmbeddedCallback ) {
            this.onSWFEmbeddedCallback.call( null );
        }
    }
    
    // on
    // type: type name
    // callback: function

    p2p.prototype.on = function( type, callback ) {
        if( this.onCallbacks[ type ] === undefined )
            this.onCallbacks[ type ] = [];
        
        this.onCallbacks[ type ].push( callback );
    }

    p2p.prototype.callOnCallbacks = function( name, parameters ) {
        var callbacks = this.onCallbacks[ name ];
        if( callbacks !== undefined && callbacks.length !== undefined )
            for( var i = 0, len = callbacks.length; i < len; i++ )
                callbacks[ i ].call( null, parameters );
        
    }


    // connect
    // parameters:
    // uri: connect uri
    // group: name of group to connect to
    
    p2p.prototype.connect = function( url ) {
        this.url = url;
        
        // need to wait for the swf constructor to run
        
        if( this.swf.connect === undefined ) {
            var scope = this;
            var method = this.connect;
            setTimeout( function() { method.call( scope, url ) }, 33 );
        } else {
            this.swf.connect( this.url ); 
        }
    }
    
    p2p.prototype.onConnect = function( parameters ) {
        this.callOnCallbacks( "connect", parameters );
    }


    // joinGroup
    // parameters:
    // name: name of group
    // post: allow posting true/false
    // stream: allow multicast streams true/false
    // replicate: allow object replication true/false
    // password: post/stream password
    
    p2p.prototype.joinGroup = function( group ) {

        if( group === undefined ) {
            group = {};
            group.name = "group" + parseInt( "" + Math.random() * 10000 );
            group.post = true;
            group.stream = false;
            group.replicate = false;
            group.password = undefined;
        }

        this.group = group;
        this.swf.joinGroup( this.group );
    }

    p2p.prototype.onJoinGroup = function( result ) {
        this.callOnCallbacks( "joinGroup", result );
    }
    
    p2p.prototype.onNeighbor = function( result ) {
        this.callOnCallbacks( "neighbor", result );
    }


    // post
    // parameters: message object
    
    p2p.prototype.post = function( message ) {
        this.swf.post( message );
    }
    
    p2p.prototype.onPost = function( message ) {
        this.callOnCallbacks( "post", message );
    }
    
    p2p.prototype.stream = function( message ) {
        // todo
    }
    
    p2p.prototype.onStream = function( message ) {
        // todo
    }
    
    p2p.prototype.replicate = function( message ) {
    }
    
    p2p.prototype.onReplicate = function( message ) {
    }
    
    p2p.prototype.onUnhandled = function( result ) {
        console.warn( "P2P.onUnhandled: " );
        console.warn( result );
    }

    //--- static ---
    
    p2p.getInstanceById = function( id ) {
        return p2pInstances[ id ];
    } 

    p2p.swfPath = "P2P.swf";
    
    return p2p;
})();


// P2PRelay function
// this is the global function used to relay calls
// from Flash into the P2P instance.

P2PRelay = function( P2PId, functionName, parameters ) {
    P2P.getInstanceById( P2PId )[ functionName ]( parameters );
}

