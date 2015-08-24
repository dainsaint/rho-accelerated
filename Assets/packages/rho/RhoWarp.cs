using UnityEngine;
using System.Collections;

public class RhoWarp : MonoBehaviour {

	public RhoKernel kernel;

	[Space(5)]
	public float radius;
	public float strength;

	
	// Update is called once per frame
	public void UpdateParameters () 
	{
		Material m = kernel.material;

		m.SetVector("_Position", transform.position);
		m.SetFloat("_Radius", radius);
		m.SetFloat("_Strength", strength);
	}

	public void StepKernel(float time, float deltaTime, RhoBuffer buffer )
	{
		// GPGPU buffer swap
		buffer.Swap();

		Material m = kernel.material;
		m.SetVector("_TimeParams", new Vector2(time, deltaTime));

		// velocity update
		m.SetTexture("_PositionTex", buffer.positionIn);
		m.SetTexture("_VelocityTex", buffer.velocityIn);
		Graphics.Blit(null, buffer.velocityOut, m, 1);

		// position update
		m.SetTexture("_VelocityTex", buffer.velocityOut);
		Graphics.Blit(null, buffer.positionOut, m, 0);
	}


	void OnDrawGizmos()
	{
		Gizmos.DrawWireSphere( transform.position, radius );
	}


}
