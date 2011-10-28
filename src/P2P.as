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
	import flash.system.Security;
	import flash.utils.getTimer;
	
	
	//--- class ------------------------------------------------------
	
	public class P2P extends Sprite {
		
		//--- variables ----------------------------------------------
		
		private var m_NetConnection	:NetConnection;
		private var m_Time			:Number;
		private var m_GroupSpec		:GroupSpecifier;
		private var m_NetGroup		:NetGroup;
		private var m_Id:String;
		
		
		//--- methods ------------------------------------------------
		
		//--- construct ---
		
		public function P2P() {
			
			if( !ExternalInterface.available )
				throw new Error( "FlowJS.construct: External Interface not available." );
			else
				Security.allowDomain( "*" );

			m_Id = loaderInfo.parameters.id;

			trace( "P2P.construct: Id is " + m_Id );
			
			ExternalInterface.addCallback( "connect", connect );
			ExternalInterface.addCallback( "joinGroup", joinGroup );
		}
		
		public function connect( uri:String ):void {
			
			graphics.beginFill( 0x0, 1 );
			graphics.drawRect( 0, 0, 100, 100 );
			graphics.endFill();
			
			m_NetConnection = new NetConnection();
			m_NetConnection.client = this;
			m_NetConnection.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
			m_NetConnection.connect( uri );
		}
		
		public function joinGroup( name:String ):void {
			m_GroupSpec = new GroupSpecifier( name );
			m_GroupSpec.serverChannelEnabled = true;
			m_GroupSpec.objectReplicationEnabled = true;
			m_GroupSpec.postingEnabled = true;
			
			m_NetGroup = new NetGroup( m_NetConnection, m_GroupSpec.groupspecWithAuthorizations());
			m_NetGroup.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
		}
		
		
		//--- serialize ---
		
		private function serialize( message:Object ):void {
		
		}

		
		//--- onConnectionNetStatus ---
		
		private function onNetStatus( e:NetStatusEvent ):void {
		
			trace( e.info.code );
			
			switch( e.info.code ) {
				
				case "NetConnection.Connect.Success":
					m_Time = getTimer();
					ExternalInterface.call( "P2PRelay", m_Id, "onConnect", "success" );
					break;
				
				case "NetGroup.Connect.Success":
					break;
				
				case "NetGroup.Posting.Notify":
					ExternalInterface.call( "P2PRelay", m_Id, "onMessage", e.info.message );
					break;
			}
		}
	}

}











