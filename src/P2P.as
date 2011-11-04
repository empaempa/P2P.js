//--------------------------------------------------------------------
//--------------------------------------------------------------------
//
// public class FlowJS extends Sprite : 
// Author: Mikael Emtinger
//
//--------------------------------------------------------------------
//--------------------------------------------------------------------

package {
	
	//--- imports ----------------------------------------------------
	
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.NetStatusEvent;
	import flash.external.ExternalInterface;
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.net.NetGroupReceiveMode;
	import flash.net.NetGroupReplicationStrategy;
	import flash.net.NetStream;
	import flash.system.Security;
	import flash.utils.getTimer;
	
	
	//--- class ------------------------------------------------------
	
	public class P2P extends Sprite {
		
		//--- variables ----------------------------------------------
		
		private var m_NetConnection	:NetConnection;
		private var m_Time			:Number;
		private var m_GroupSpec		:GroupSpecifier;
		private var m_NetGroup		:NetGroup;
		private var m_NetStream		:NetStream;
		private var m_Id			:String;
		private var m_PostCounter   :int = 0;
		private var m_StreamsIn		:Object;
		
		
		//--- methods ------------------------------------------------
		
		//--- construct ---
		
		public function P2P() {
			
			if( !ExternalInterface.available )
				throw new Error( "FlowJS.construct: External Interface not available." );
			else
				Security.allowDomain( "*" );

			m_Id = loaderInfo.parameters.id;

			ExternalInterface.addCallback( "connect", connect );
			ExternalInterface.addCallback( "joinGroup", joinGroup );
			ExternalInterface.addCallback( "post", post );
			ExternalInterface.addCallback( "stream", stream );
			ExternalInterface.addCallback( "replicate", replicate );
			
			m_StreamsIn = {};
		}
		
		
		//--- connect ---
		
		public function connect( uri:String ):void {
			
			if( m_NetConnection ) {
				m_NetConnection.close();
				m_NetConnection = null;
			}			
			
			m_NetConnection = new NetConnection();
			m_NetConnection.client = this;
			m_NetConnection.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
			m_NetConnection.connect( uri );
		}
		
		
		//--- join group ---
		
		public function joinGroup( parameters:Object ):void {
			
			// todo: add params for posting/replication/stream
			
			m_GroupSpec = new GroupSpecifier( parameters.name );
			m_GroupSpec.serverChannelEnabled = true;
			m_GroupSpec.postingEnabled = parameters.post != undefined ? parameters.post : true;
			m_GroupSpec.multicastEnabled = parameters.stream != undefined ? parameters.stream : true;
			m_GroupSpec.objectReplicationEnabled = parameters.replication != undefined ? parameters.replication : false;
			
			if( parameters.password != undefined ) {
				if( m_GroupSpec.postingEnabled )
					m_GroupSpec.setPostingPassword( parameters.password );
				
				if( m_GroupSpec.multicastEnabled )
					m_GroupSpec.setPublishPassword( parameters.password );
			}
			
			m_NetGroup = new NetGroup( m_NetConnection, m_GroupSpec.groupspecWithAuthorizations());
			m_NetGroup.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
		}
		
		
		//--- post ---
		
		public function post( message:Object ):void {
			if( m_NetConnection && m_NetConnection.connected && m_NetGroup ){
				message.p2p = m_PostCounter++;
				m_NetGroup.post( message );
			} else {
				callJS( "onError", { error: "Posting before connecting and joining group" } );
			}
		}

		
		
		//--- stream ---
		
		public function stream( message:Object ):void {
			if( m_NetConnection && m_NetConnection.connected && m_NetGroup ) {
				if( !m_NetStream ) {
					m_NetStream = new NetStream( m_NetConnection, NetStream.DIRECT_CONNECTIONS );
					m_NetStream.client = this;
					m_NetStream.dataReliable = false;
					m_NetStream.bufferTime = 0;
					m_NetStream.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
					m_NetStream.publish( "stream" );
				}
				
				m_NetStream.send( "onStream", message );
			} else {
				callJS( "onError", { error: "Streaming before connecting and joining group" } );
			}
		}
		
		public function onStream( message:Object ):void {
			callJS( "onStream", message );
		}
		
		
		//--- replicate ---
		
		public function replicate( message:Object ):void {
			// todo: 
			// http://www.flashrealtime.com/file-share-object-replication-flash-p2p/
		}

		
		//--- call ---
		
		private function callJS( method:String, message:Object ):void {
			try {
				ExternalInterface.call( "P2PRelay", m_Id, method, message );
			} catch( e:Error ) {
				throw e;
			}
		}
		
		//--- onNetStatus ---
		
		private function onNetStatus( e:NetStatusEvent ):void {
			switch( e.info.code ) {
				case "NetConnection.Connect.Success":
					ExternalInterface.call( "P2PRelay", m_Id, "onConnect", { sucess: true } );
					break;
				
				case "NetConnection.Connect.Rejected":
				case "NetConnection.Connect.Failed":
				case "NetConnection.Connect.Closed":
				case "NetConnection.Connect.IdleTimeout":
				case "NetConnection.Connect.Rejected":
					callJS( "onDisconnect", { success: false, reason: e.info.code } );
					break;
				
				case "NetGroup.Connect.Success":
					callJS( "onJoinGroup", { success: true } );
					break;
				
				case "NetGroup.Connect.Failed":
				case "NetGroup.Connect.Rejected":
					callJS( "onJoinGroup", { success: false, reason: e.info.code } );
					break;

				case "NetGroup.Posting.Notify":
				case "NetGroup.SendTo.Notify":
					callJS( "onPost", e.info.message );
					break;
				
/*				case "NetGroup.Neighbor.Connect":
					callJS( "onNeighbor", { neighbor: e.info.neighbor, peerId: e.info.peerID } );
					break;
				
					callJS( "onNeighborDisconnect", { neighbor: e.info.neighbor, peerId: e.info.peerID } );
					break;
*/					
				case "NetGroup.Neighbor.Connect":
					if( m_StreamsIn[ e.info.name ] == undefined ) {
						m_StreamsIn[ e.info.name ] = new NetStream( m_NetConnection, e.info.peerID );
						m_StreamsIn[ e.info.name ].client = this;
						m_StreamsIn[ e.info.name ].bufferTime = 0;
						m_StreamsIn[ e.info.name ].play( "stream" );
						callJS( "onInfo", { code: e.info.code, name: e.info.name, peerID: e.info.peerID } );
					}
					break;
				
				case "NetGroup.Neighbor.Disconnect":
					if( m_StreamsIn[ e.info.name ] != undefined ) {
						m_StreamsIn[ e.info.name ].close();
						delete m_StreamsIn[ e.info.name ];
						callJS( "onInfo", { code: e.info.code, name: e.info.name } );
					}
					break;
				
				case "NetStream.Connect.Success":
				case "NetStream.Connect.Closed":
				case "NetStream.Publish.Start":
					callJS( "onInfo", { code: e.info.code } );
					break;					
				
		/*		default:
					callJS( "onError", { error: "Unhandled NetStatus Event", info: e.info } );
					break;*/
			}
		}
	}
}











