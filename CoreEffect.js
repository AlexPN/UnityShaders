public var CoreParticle: GameObject;
public var CoreSparks: GameObject[];

function Start () {
	var got: Transform = this.gameObject.transform;
	for (var s: int = 0; s < CoreSparks.Length; s++) {
		CoreSparks[s] = Instantiate(CoreParticle,got.position,got.rotation);
	}
	
}

function Update () {
	var sinTime: float;
	sinTime = 0.5*Mathf.Sin(Time.time)/4 + 1;
	this.gameObject.transform.localScale = Vector3(sinTime,sinTime,sinTime);
	this.gameObject.renderer.material.SetFloat("_Width",0.05*Mathf.Cos(Time.time)+0.10);
	
	for (var i: GameObject in CoreSparks) {
		i.rigidbody.AddRelativeForce(Vector3(Random.Range(-0.1,0.1),Random.Range(-0.2,0.2),Random.Range(-0.1,0.1))*10,ForceMode.Force);
		if (Vector3.Distance(i.transform.position,this.gameObject.transform.position) > 0.3) {
			i.rigidbody.AddForce(this.gameObject.transform.position - i.transform.position*5,ForceMode.Force);
		}
		if (Vector3.Distance(i.transform.position,this.gameObject.transform.position) > 1) {
			i.transform.position = this.gameObject.transform.position;
		}
	}
	
}