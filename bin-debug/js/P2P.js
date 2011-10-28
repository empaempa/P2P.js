/*
* P2P.JS
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
    
    function p2p( id, onSWFEmbeddedCallback ) {
        
        this.id = id;
        this.swf = undefined;
        this.onSWFEmbeddedCallback = onSWFEmbeddedCallback;
        
        p2pInstances[ this.id ] = this;
        
        var container = document.createElement( "div" );
        container.id = "P2P_containerDiv_" + this.id;
        container.p2pInstance = this;
        
        var swfContainer = document.createElement( "div" );
        swfContainer.id = "P2P_swfDiv_" + this.id;
        
       document.body.appendChild( container );
       container.appendChild( swfContainer );
        

        var flashVariables = {};
        var flashParameters = {};
        var flashAttributes = {};
        
        flashVariables.id = this.id;
        flashParameters.quality = "low";
        flashParameters.allowscriptaccess = "always";
        flashAttributes.id = "P2P_swf_" + this.id;
        flashAttributes.name = "P2P_swf_" + this.id;

        swfobject.embedSWF( P2P.swfPath, "P2P_swfDiv_" + this.id, "100%", "100%", "10.2", "", flashVariables, flashParameters, flashAttributes, this.onSWFEmbed );
    }
    
    p2p.prototype.onSWFEmbed = function( result ) {
        
        var p2pInstance = result.ref.parentNode.p2pInstance;
        p2pInstance.swf = swfobject.getObjectById( "P2P_swf_" + p2pInstance.id );
        
        if( p2pInstance.onSWFEmbeddedCallback ) {
            p2pInstance.onSWFEmbeddedCallback.call( null );
        }
    }
    
    p2p.prototype.connect = function( url, group ) {
        this.url = url;
        this.group = group;
        
        // need to wait for the swf constructor to run
        
        if( this.swf.connect === undefined ) {
            var scope = this;
            var connectMethod = this.connect;
            setTimeout( function() { connectMethod.call( scope, url, group ) }, 33 );
        } else {
            console.log( "P2P.connect: " + url, group );
            this.swf.connect( url ); 
        }
    }
    
    p2p.prototype.onConnect = function( parameters ) {
        console.log( "P2P.onConnect: " + this.id );
        
        if( this.group !== undefined ) {
            this.joinGroup( this.group );
        }
    }
    
    p2p.prototype.joinGroup = function( group ) {
        if( this.group === undefined ) {
            this.group = "group" + Math.random() * 10000;
        }
        
        this.swf.joinGroup( group );
    }
    
    p2p.prototype.onMessage = function( parameters ) {
        console.log( "P2P.onMessage: " + this.id );
    }

    // static
    
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
    console.log( "P2PRelay: " + P2PId, functionName, parameters );
    P2P.getInstanceById( P2PId )[ functionName ]( parameters );
}

