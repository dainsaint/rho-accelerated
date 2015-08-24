using UnityEngine;
using System.Collections;


namespace Duet
{

	public class MouseFollow : MonoBehaviour 
	{

		public float sensitivity = 1.0f;
		public float accel = 0.1f;

		public bool isRelative = false;

		Vector3 targetPosition;
		
		void Update () 
		{

				if( Input.mousePosition.x >= 0 && Input.mousePosition.x <= Screen.width &&
					Input.mousePosition.y >= 0 && Input.mousePosition.y <= Screen.height )
				{
					transform.position = Camera.main.ScreenToWorldPoint( new Vector3( Input.mousePosition.x, Input.mousePosition.y, -Camera.main.transform.position.z ) );
				}
			


		}

		public void SetPosition( Vector3 position )
		{
			targetPosition = position;
		}
	}

}