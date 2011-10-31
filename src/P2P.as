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
			m_GroupSpec.multicastEnabled = parameters.stream != undefined ? parameters.stream : false;
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
			message.p2p = m_PostCounter++;
			m_NetGroup.post( message );
		}

		
		//--- stream ---
		
		public function stream( message:String ):void {
			// todo:
			// http://www.flashrealtime.com/multicast-explained-flash-101-p2p/
		}
		
		
		//--- replicate ---
		
		public function replicate( message:Object ):void {
			// todo: 
			// http://www.flashrealtime.com/file-share-object-replication-flash-p2p/
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
					ExternalInterface.call( "P2PRelay", m_Id, "onConnect",{ success: false, reason: e.info.code } );
					break;
				
				
				case "NetGroup.Connect.Success":
					ExternalInterface.call( "P2PRelay", m_Id, "onJoinGroup", { success: true } );
					break;
				
				case "NetGroup.Connect.Failed":
				case "NetGroup.Connect.Rejected":
					ExternalInterface.call( "P2PRelay", m_Id, "onJoinGroup", { success: false, reason: e.info.code } );
					break;

				
				case "NetGroup.Posting.Notify":
				case "NetGroup.SendTo.Notify":
					ExternalInterface.call( "P2PRelay", m_Id, "onPost", e.info.message );
					break;
				
				case "NetGroup.Neighbor.Connect":
					ExternalInterface.call( "P2PRelay", m_Id, "onNeighbor", { neighbor: e.info.neighbor, peerId: e.info.peerID } );
					break;
				
				case "NetGroup.Neighbor.Disconnect":
					ExternalInterface.call( "P2PRelay", m_Id, "onNeighborDisconnect", { neighbor: e.info.neighbor, peerId: e.info.peerID } );
					break;
					
				default:
					ExternalInterface.call( "P2PRelay", m_Id, "onUnhandled", e.info );
					trace( "Unhandled onNetStatus: " + e.info.code );

			}
		}
	}

}











