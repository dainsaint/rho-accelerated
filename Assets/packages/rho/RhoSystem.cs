using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;

public class RhoSystem : MonoBehaviour 
{

	

 #region Basic Configuration

	[SerializeField]
	[Header("System Settings")]

	public RhoMeshInfo info;
	public float rate = 10;
	public float speed = 1f;
	public float drag = 0.9f;

	public Vector3 direction;

	public List<RhoWarp> warps = new List<RhoWarp>();

	#endregion

		
	#region Render Settings

	[Header("Render Settings")]
	public Material material;

	public float lineWidth = 0.1f;

	public Color color = Color.white;

	
	RhoBuffer buffer;

	#endregion


	#region Misc Settings

	[SerializeField]
	int _randomSeed = 0;

	#endregion

	#region Custom Shaders


	public RhoKernel kernel;


	#endregion

	#region Private Objects And Properties

	Mesh _mesh;

	bool _needsReset = true;
	float _time;


	#endregion

	#region Resource Management

	[Header("Debug Settings")]
	public bool showDebug = false;

	public void NotifyConfigChange()
	{
		_needsReset = true;
	}

	Material CreateMaterial(Shader shader)
	{
		var material = new Material(shader);
		material.hideFlags = HideFlags.DontSave;
		return material;
	}



	Mesh CreateMesh()
	{																																																																				
		var nx = info.historyLength;
		var ny = info.LinesPerDraw;

		var inx = 1.0f / nx;
		var iny = 1.0f / info.TotalLineCount;

		// vertex and texcoord array
		var va = new Vector3[(nx - 2) * ny * 2];
		var ta = new Vector2[(nx - 2) * ny * 2];
		var uv = new Vector2[(nx - 2) * ny * 2];

		var offs = 0;
		for (var y = 0; y < ny; y++)
		{
			var v = iny * y;
			for (float x = 1; x < nx - 1; x++)
			{
				va[offs] = Vector3.right * -0.5f;
				va[offs + 1] = Vector3.right * 0.5f;
				ta[offs] = ta[offs + 1] = new Vector2(inx * x, v);
				uv[offs] = new Vector2( 0 , 1 - (x-1)/nx );
				uv[offs + 1] = new Vector2( 1 , 1 - (x-1)/nx );
				offs += 2;
			}
		}

		// index array
		var ia = new int[ny * (nx - 3) * 6];
		offs = 0;
		for (var y = 0; y < ny; y++)
		{
			var vi = y * (nx - 2) * 2;
			for (var x = 0; x < nx - 3; x++)
			{
				ia[offs++] = vi;
				ia[offs++] = vi + 1;
				ia[offs++] = vi + 2;
				ia[offs++] = vi + 1;
				ia[offs++] = vi + 3;
				ia[offs++] = vi + 2;
				vi += 2;
			}
		}

		// create a mesh object
		var mesh = new Mesh();
		mesh.hideFlags = HideFlags.DontSave;
		mesh.vertices = va;
		mesh.uv = ta;
		mesh.uv2 = uv;
		mesh.SetIndices(ia, MeshTopology.Triangles, 0);
		mesh.Optimize();

		// avoid begin culled
		mesh.bounds = new Bounds(Vector3.zero, Vector3.one * 100);

		return mesh;
	}


	void StepKernel(float time, float deltaTime)
	{
		buffer.Swap();

		Material m = kernel.material;

		m.SetVector("_Direction", direction);
		m.SetFloat("_Drag", drag);
		m.SetFloat("_Speed", speed);
		m.SetFloat("_RandomSeed", _randomSeed);
		m.SetFloat("_Rate", rate);
	
		m.SetVector("_TimeParams", new Vector2(time, deltaTime));


		// velocity update
		m.SetTexture("_PositionTex", buffer.positionIn);
		m.SetTexture("_VelocityTex", buffer.velocityIn);
		Graphics.Blit(null, buffer.velocityOut, m, 3);

		// position update
		m.SetTexture("_VelocityTex", buffer.velocityOut);
		Graphics.Blit(null, buffer.positionOut, m, 2);
	}

	void UpdateLineShader()
	{
		var m = material;

		m.SetFloat("_LineWidth", lineWidth);
		m.SetColor("_Color1", color);	

		m.SetTexture("_PositionTex", buffer.positionOut);
		m.SetTexture("_VelocityTex", buffer.velocityOut);
	}

	void ResetResources()
	{
		// parameter sanitization
		info.numParticles = Mathf.Clamp(info.numParticles, 1, 8192);
		info.historyLength = Mathf.Clamp(info.historyLength, 8, 1024);

		// mesh object
		if (_mesh) DestroyImmediate(_mesh);
		_mesh = CreateMesh();

		if( buffer == null )
			buffer = new RhoBuffer( info );

		buffer.Reset();

		kernel.material.SetVector("_Direction", direction);
		kernel.material.SetFloat("_Speed", speed);


		// buffer initialization
		Graphics.Blit(null, buffer.positionOut, kernel.material, 0);
		Graphics.Blit(null, buffer.velocityOut, kernel.material, 1);

		_time = 0;
		
		_needsReset = false;

	}

	#endregion

	#region MonoBehaviour Functions

	void Reset()
	{
		_needsReset = true;
	}

	void OnDestroy()
	{
		if (_mesh) DestroyImmediate(_mesh);

		buffer.Destroy();


		if (kernel.material)  DestroyImmediate(kernel.material);
		

		//if ( material )    	DestroyImmediate(material);
	}

	void Update()
	{
		if (_needsReset) ResetResources();

		if( Input.GetKeyDown( KeyCode.Space ) )
		{
			ResetResources();
		}


		// Variable time step.
		float deltaTime = Time.smoothDeltaTime;
		int steps = 1;
	
		// Time steps.
		for (var i = 0; i < steps; i++)
		{
			_time += deltaTime;


			for(var w = 0; w < warps.Count; w++)
			{
				RhoWarp warp = warps[w];
				if( warp == null || warp.enabled == false) continue;
				warp.UpdateParameters();
				warp.StepKernel( _time, deltaTime, buffer );
			}

			StepKernel(_time, deltaTime);
		}
		

		// Draw lines.
		UpdateLineShader();

		var matrix = transform.localToWorldMatrix;
		var stride = info.LinesPerDraw;
		var total = info.TotalLineCount;

		var props = new MaterialPropertyBlock();
		var uv = new Vector2(0.5f / info.historyLength, 0);

		for (var i = 0; i < total; i += stride)
		{
			uv.y = (0.5f + i) / total;
			props.SetVector("_BufferOffset", uv);
			Graphics.DrawMesh(
				_mesh, matrix, material, 0, null, 0, props,
				false, false);
		}
	}

	#endregion


	void OnGUI()
	{
		if( buffer != null && showDebug )
			buffer.DebugGUI();
	}


}


public enum RhoProcessingPass
{
	InitPosition = 0,
	InitVelocity = 1,
	UpdatePosition = 2,
	UpdateVelocity = 3
}