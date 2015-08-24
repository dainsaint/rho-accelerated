using UnityEngine;
using System.Collections;


[System.Serializable]
public class RhoMeshInfo  {

	public int numParticles = 32;
	public int historyLength = 32;


	// Returns the actual total number of lines.
	public int TotalLineCount {
		get { return numParticles - numParticles % DrawCount; }
	}

	int DrawCount {
		get {
			var total = historyLength * numParticles * 2;
			if (total < 65000) return 1;
			return total / 65000 + 1;
		}
	}

	// Returns how many lines in one draw call.
	public int LinesPerDraw {
		get {
			return numParticles / DrawCount;
		}
	}

}
