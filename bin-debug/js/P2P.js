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
    
    p2p.prototype.hide = function() {
        this.swf.style.width = "0px";
        this.swf.style.height = "0px";
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
                callbacks[ i ]( parameters );
        
    }


    // connect
    // parameters:
    // uri: connect uri
    // group: name of group to connect to
    
    p2p.prototype.connect = function( url ) {
        this.url = url;
        
        // need to wait for the swf constructor to run
        
        if( this.swf === undefined || this.swf.connect === undefined ) {
            var scope = this;
            var method = this.connect;
            setTimeout( function() { method.call( scope, url ) }, 33 );
        } else {
            console.log( "P2P.connect: " + this.url );
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
        if( this.swf.joinGroup ) {
            if( group === undefined ) {
                group = {};
                group.name = "group" + parseInt( "" + Math.random() * 10000 );
                group.post = true;
                group.stream = true;
                group.replicate = false;
                group.password = undefined;
            }

            this.group = group;
            this.swf.joinGroup( this.group );
        } else {
            console.error( "P2P.joinGroup: P2P SWF not yet initialized, please await init." );
        }
    }

    p2p.prototype.onJoinGroup = function( result ) {
        this.callOnCallbacks( "joinGroup", result );
    }
    
    p2p.prototype.onNeighbor = function( result ) {
        this.callOnCallbacks( "neighbor", result );
    }

    p2p.prototype.onNeighborDisconnect = function( result ) {
        this.callOnCallbacks( "neighborDisconnect", result );
    }

    p2p.prototype.onDisconnect = function( result ) {
        this.callOnCallbacks( "disconnect", result );
    }

    // post
    // parameters: message object
    
    p2p.prototype.post = function( message ) {
        if( this.swf.post ) 
            this.swf.post( message );
        else
            console.warn( "P2P.post: post not available as SWF isn't initialized. Message discarded." );
    }
    
    p2p.prototype.onPost = function( message ) {
        this.callOnCallbacks( "post", message );
    }

    p2p.prototype.stream = function( message ) {
        if( this.swf.stream )
            this.swf.stream( message );
        else
            console.warn( "P2P.stream: stream not available as SWF isn't initialized. Message discarded." );
    }
    
    p2p.prototype.onStream = function( message ) {
        this.callOnCallbacks( "stream", message );
    }
    
    
    p2p.prototype.replicate = function( message ) {
        // todo
    }
    
    p2p.prototype.onReplicate = function( message ) {
        this.callOnCallbacks( "replicate", message );
    }
    
    p2p.prototype.onError = function( message ) {
        //this.callOnCallbacks( "error", message );
        console.warn( "P2P.onError: ", message );
    }
    
    p2p.prototype.onInfo = function( message ) {
        console.warn( "P2P.onInfo: ", message );
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
    var instance = P2P.getInstanceById( P2PId );
    if( instance ) {
        if( instance[ functionName ] ) {
            instance[ functionName ]( parameters );
        } else {
            console.error( "P2P.P2PRelay: Function name " + functionName + " does not exist" );
        }
    } else {
        console.error( "P2P.P2PRelay: Instance " + P2PId + " does not exist" );
    }
}

