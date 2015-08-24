using UnityEngine;
using System.Collections;


[System.Serializable]
public class RhoKernel {

	public Shader shader;
	
	Material _material;

	public Material material
	{
		get
		{
			if (!_material) _material = CreateMaterial( shader );
			return _material;
		}
	}

	Material CreateMaterial(Shader shader)
	{
		var material = new Material(shader);
		material.hideFlags = HideFlags.DontSave;
		return material;
	}

}
