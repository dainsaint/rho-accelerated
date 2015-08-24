using UnityEngine;
using System.Collections;

public class RhoBuffer 
{
	public RhoMeshInfo info;

	public RenderTexture positionIn {get; private set;}
	public RenderTexture positionOut {get; private set;}
	public RenderTexture velocityIn {get; private set;}
	public RenderTexture velocityOut {get; private set;}


	public RhoBuffer( RhoMeshInfo info )
	{
		this.info = info;
	}

	public void Reset()
	{
		DestroyBuffers();

		positionIn = CreateBuffer(false);
		positionOut = CreateBuffer(false);
		velocityIn = CreateBuffer(true);
		velocityOut = CreateBuffer(true);
	}

	public void Swap()
	{
		var pb = positionIn;
		var vb = velocityIn;
		positionIn = positionOut;
		velocityIn = velocityOut;
		positionOut = pb;
		velocityOut = vb;
	}

	public void Destroy()
	{
		DestroyBuffers();
	}

	public void DebugGUI()
	{
		if( !positionOut )
			return;

		float scale = 1;
		GUI.DrawTexture( new Rect( 0, 0, positionOut.width * scale, positionOut.height * scale ), positionOut, ScaleMode.StretchToFill, true );

		GUI.DrawTexture( new Rect( positionOut.width * scale + scale * 4, 0, velocityOut.width * scale, velocityOut.height * scale ), velocityOut, ScaleMode.StretchToFill, false );
	}

	void DestroyBuffers()
	{
		GameObject.DestroyImmediate( positionIn  );
		GameObject.DestroyImmediate( positionOut );
		GameObject.DestroyImmediate( velocityIn  );
		GameObject.DestroyImmediate( velocityOut );
	}

	RenderTexture CreateBuffer(bool forVelocity)
	{
		var format = RenderTextureFormat.ARGBFloat;
		var width = forVelocity ? 1 : info.historyLength;
		var buffer = new RenderTexture(width, info.TotalLineCount, 0, format);
		buffer.hideFlags = HideFlags.DontSave;
		buffer.filterMode = FilterMode.Point;
		buffer.wrapMode = TextureWrapMode.Clamp;
		return buffer;
	}

	
}
