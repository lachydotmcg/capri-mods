using System;
using System.IO;
using System.Drawing;
using System.Collections.Generic;
using System.Threading;
using System.Diagnostics;
using CapriDesktop;
using CapriNightCity;

public sealed class TestHost : ICapriHost
{
    public string Folder { get; set; }
    public readonly List<string> Lines=new List<string>();
    public void Say(string line) { lock(Lines) Lines.Add(line); }
    public void Log(string line) { }
    public Bitmap Art(string name) { return null; }
    public void PlayIntro() { }
    public void Sound(string name) { }
}
public static class ClientTests
{
    private static int count;
    static void Check(bool value,string name) { if(!value) throw new Exception("FAIL "+name); count++; Console.WriteLine("PASS "+name); }
    static string Snapshot(string session,long now,string events,int seq)
    {
        return Wire.Pack("snap","session",session,"issued",now.ToString(),"ready","1","menu","0","health","80","combat","1","wanted","2",
            "target","enemy","target_name","Enemy","eligible","1","assist","1","event_seq",seq.ToString())+events;
    }
    static void PublishSnapshot(string folder,string session,long now,string extras,int seq)
    { Wire.Publish(Path.Combine(folder,"snapshot.txt"),Snapshot(session,now,extras,seq)); }
    static void PublicSetupTest(string root)
    {
        string folder=Path.Combine(root,"public-setup-"+Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(folder);
        NightCityMod mod=new NightCityMod();
        try {
            mod.Start(new TestHost { Folder=folder });
            string selected=File.ReadAllText(Path.Combine(folder,"game-folder.txt"));
            Check(selected==Path.Combine(folder,"select-game-folder"),"fresh import uses its own unconfigured data path");
            Check(!Directory.Exists(selected),"fresh import does not create or write a game directory");
            Check(mod.Heard("night city status"),"fresh import accepts diagnostics before game selection");
        } finally { mod.Stop(); }
        Wire.Publish(Path.Combine(folder,"game-folder.txt"),Path.Combine(folder,"selected-bridge"));
        mod=new NightCityMod();
        try {
            mod.Start(new TestHost { Folder=folder });
            Check(File.ReadAllText(Path.Combine(folder,"game-folder.txt"))==Path.Combine(folder,"selected-bridge"),"existing game selection survives restart");
        } finally { mod.Stop(); }
    }
    static void MainTests(string root)
    {
        string leases=Path.Combine(root,"lease-ownership-"+Guid.NewGuid().ToString("N")); Directory.CreateDirectory(leases);
        PublishSnapshot(leases,"owner-test",100,"",0);
        BridgeClient oldOwner=new BridgeClient(leases), newOwner=new BridgeClient(leases);
        oldOwner.Tick(100); newOwner.Tick(100); oldOwner.ReleaseLease();
        Check(File.Exists(Path.Combine(leases,"client.txt")),"old mod unload cannot delete a replacement client's lease");
        newOwner.ReleaseLease(); Check(!File.Exists(Path.Combine(leases,"client.txt")),"current lease owner releases its heartbeat");
        string blocked=Path.Combine(leases,"directory-target"); Directory.CreateDirectory(blocked); bool publishFailed=false;
        try { Wire.Publish(blocked,"packet"); } catch(IOException) { publishFailed=true; }
        Check(publishFailed && Directory.GetFiles(leases,"*.writing").Length==0,"failed atomic publication cleans its uniquely named temporary file");
        Check(Wire.Parse("protocol=1\nid=a\ncommit=a\n")!=null,"complete snapshot accepted");
        Check(Wire.Parse("protocol=1\nid=a\ncommit=b\n")==null,"incomplete snapshot ignored");
        Check(Wire.Parse(new string('x',32769))==null,"oversized snapshot ignored");
        Check(!Wire.Fresh(Wire.Parse("protocol=1\nid=a\nissued=10\ncommit=a\n"),20),"stale heartbeat rejected");
        Check(!Wire.Fresh(Wire.Parse("protocol=1\nid=a\nissued=30\ncommit=a\n"),20),"future heartbeat rejected");
        foreach(string phrase in new[]{"ghost spike","Capri, ghost spike!","Hey Capri, ghost spike"}) Check(BridgeClient.Keyword(phrase)=="spike","keyword: "+phrase);
        Check(BridgeClient.Keyword("don't erase target")==null && BridgeClient.Keyword("should we use blackwall breach")==null,"negated and conversational phrases cannot execute hacks");
        Check(BridgeClient.Keyword("neural burn")=="burn" && BridgeClient.Keyword("puppet lock")=="lock" && BridgeClient.Keyword("erase target")=="erase","custom hack keywords");
        Check(BridgeClient.Keyword("open the blackwall")=="blackwall" && BridgeClient.Keyword("cover me")=="assist_on" && BridgeClient.Keyword("stand down")=="assist_off","Blackwall and assistance keywords");
        foreach(string phrase in new[]{"kill the guy in front of me","Capri, kill the guy in front of me.","Could you please kill that guy?","please eliminate the enemy I'm looking at","take him out","finish off the guard"})
            Check(BridgeClient.Keyword(phrase)=="kill","natural lethal intent: "+phrase);
        foreach(string phrase in new[]{"blind the guy","Capri, blind him!","can you blind the guy in front of me please","reboot his optics","reboot that guy's optics"})
            Check(BridgeClient.Keyword(phrase)=="blind","natural blindness: "+phrase);
        Check(BridgeClient.Keyword("jam his gun")=="jam" && BridgeClient.Keyword("disable their weapon")=="jam","natural weapon jam");
        Check(BridgeClient.Keyword("stun the enemy")=="lock" && BridgeClient.Keyword("knock him out")=="collapse","stun and collapse intents");
        foreach(string phrase in new[]{"hack that guy","deal with the enemy in front of me","use the best hack on him","do your thing","use whatever hack you want"})
            Check(BridgeClient.Keyword(phrase)=="smart","adaptive intent: "+phrase);
        Check(BridgeClient.Keyword("disable him")=="control","disable asks for control rather than an execution");
        foreach(string phrase in new[]{"don't kill the guy in front of me","do not blind him","never kill that guy","should we kill him","how do I blind the guy","he said kill the guy","kill him and blind her","can you explain how to kill him","don't use whatever hack you want"})
            Check(BridgeClient.Keyword(phrase)==null,"non-command/negative/compound phrase ignored: "+phrase);
        foreach(string phrase in new[]{"hack that car","hack the camera","hack the terminal","hack the turret in front of me"})
            Check(BridgeClient.Keyword(phrase)=="smart","cross-type natural target: "+phrase);
        Check(BridgeClient.Keyword("stop the car")=="brake" && BridgeClient.Keyword("accelerate that vehicle")=="accelerate","vehicle control intents");
        Check(BridgeClient.Keyword("blow it up")=="explode" && BridgeClient.Keyword("destroy the car")=="explode","vehicle destruction intents");
        Check(BridgeClient.Keyword("hack the access point")=="breach" && BridgeClient.Keyword("breach that access point")=="breach","access point intents");
        Check(BridgeClient.Keyword("turn off that camera")=="device_off" && BridgeClient.Keyword("open the door")=="open","device power and opening intents");
        Check(BridgeClient.Keyword("distract using the vending machine")=="device_distract","device distraction intent");
        Check(BridgeClient.Keyword("attack that car")=="spike" && BridgeClient.Keyword("attack the npc")=="spike","natural cross-type attack intent");
        Check(BridgeClient.Keyword("chaos mode on")=="chaos_on" && BridgeClient.Keyword("do whatever you want")=="chaos_on","explicit chaos opt-in");
        Check(BridgeClient.Keyword("stop chaos")=="chaos_off" && BridgeClient.Keyword("stand down")=="assist_off","chaos stop commands");
        Check(BridgeClient.Keyword("don't enable chaos mode")==null && BridgeClient.Keyword("what is chaos mode on")==null,"chaos negatives and explanations cannot enable it");
        Check(BridgeClient.Keyword("Capri, kill the guy in front of me. Now.")=="kill","actual spoken urgent request is routed");
        Check(BridgeClient.Keyword("Capri killed the guy in front of me.")=="kill","addressed speech-recognition killed/kill variation");
        Check(BridgeClient.Keyword("Capri, destroy the f vehicle in front of me.")=="explode","actual spoken vehicle filler is accepted");
        Check(BridgeClient.TargetSelection("kill the guy","kill")=="nearest_enemy","generic person request searches nearby enemies");
        Check(BridgeClient.TargetSelection("kill the guy in front of me","kill")=="aim" && BridgeClient.ExpectedKind("kill the guy in front of me")=="npc","front request pins aim and expects an NPC");
        Check(BridgeClient.Keyword("scan enemies")=="scan" && BridgeClient.Keyword("stop scanning")=="scan_off","scan commands");
        Check(BridgeClient.Keyword("Capri, scan!")=="scan" && BridgeClient.Keyword("scan around me")=="scan","bare scan and nearby scan reach continuous protection-style scanner");
        Check(BridgeClient.Keyword("don't scan")==null,"negated bare scan does not start scanning");
        Check(BridgeClient.Keyword("netrunner defense on")=="counter_on" && BridgeClient.Keyword("counterhack off")=="counter_off","netrunner defense mode commands");
        Check(BridgeClient.Keyword("don't enable netrunner defense")==null,"negation cannot arm netrunner retaliation");
        string[,] customPrograms={{"ghost veil","ghost_veil"},{"marionette lock","marionette"},{"dead channel","dead_channel"},{"neural siphon","siphon"},
            {"furnace lock","furnace"},{"circuit breaker","circuit_breaker"},{"crash loop","crash_loop"},{"reaper thread","reaper_thread"}};
        for(int i=0;i<customPrograms.GetLength(0);i++) {
            Check(BridgeClient.Keyword(customPrograms[i,0])==customPrograms[i,1],"custom program name: "+customPrograms[i,0]);
            Check(BridgeClient.TargetSelection(customPrograms[i,0],customPrograms[i,1])=="nearest_enemy","custom program defaults to nearest NPC: "+customPrograms[i,0]);
        }
        Check(BridgeClient.Keyword("Could you please use Ghost Veil on those three armed guards in front of me?")=="ghost_veil","polite named custom program accepts a described forward group");
        Check(BridgeClient.TargetCount("Ghost Veil on those three armed guards in front of me")==3 && BridgeClient.TargetSelection("Ghost Veil on those three armed guards in front of me","ghost_veil")=="front_group","custom programs retain group count and forward-cone routing");
        Check(BridgeClient.Keyword("Capri, put him in a crash loop!")=="crash_loop" && BridgeClient.Keyword("drain his health")=="siphon","natural Crash Loop and health-drain phrases");
        Check(BridgeClient.Keyword("fry his circuits")=="circuit_breaker" && BridgeClient.Keyword("sever their comms")=="dead_channel","custom circuit and comms phrases");
        Check(BridgeClient.Keyword("use neural siphon on that car")=="siphon" && BridgeClient.TargetSelection("use neural siphon on that car","siphon")=="aim","unsupported custom target goes to native refusal rather than computer use");
        Check(BridgeClient.Keyword("don't use crash loop on him")==null && BridgeClient.Keyword("use reaper thread on him and kill the others")==null,"negated and compound custom requests are rejected");
        Check(BridgeClient.Keyword("what does reaper thread do")==null && BridgeClient.Keyword("night city hacks")=="hacks","explanations cannot cast and catalogue has its own command");
        Check(BridgeClient.Keyword("protect me")=="protect_on" && BridgeClient.Keyword("watch my back")=="protect_on","protection on commands");
        Check(BridgeClient.Keyword("stop protecting me")=="protect_off" && BridgeClient.Keyword("don't protect me")==null,"protection off and negation");
        Check(BridgeClient.Keyword("flatline him")=="kill","flatline synonym");
        Check(BridgeClient.Keyword("Capri please just flatline those three armed guards around me")=="kill","natural nested polite prefix and group phrase");
        Check(BridgeClient.Keyword("could you flatline those three armed guards around me")=="kill","natural group description and polite request");
        Check(BridgeClient.Keyword("blind those three guards")=="blind" && BridgeClient.TargetCount("blind those three guards")==3,"group blindness and count");
        Check(BridgeClient.TargetSelection("flatline those guys in front of me","kill")=="front_group","front group uses a forward cone");
        Check(BridgeClient.TargetCount("flatline all those guys")==5 && BridgeClient.ExpectedKind("blow up those cars")=="vehicle","bounded group and vehicle type");
        Check(BridgeClient.Keyword("stealth mode on")=="stealth_on" && BridgeClient.Keyword("go loud")=="stealth_off","stealth commands");
        Check(BridgeClient.Keyword("emergency rescue on")=="emergency_on" && BridgeClient.Keyword("emergency off")=="emergency_off","rescue commands");
        string folder=Path.Combine(root,"mock-client"); Directory.CreateDirectory(folder);
        BridgeClient c=new BridgeClient(folder);
        Check(c.Queue("spike",100).Contains("offline"),"offline request refused");
        PublishSnapshot(folder,"s1",100,"event_1=1|kill|old death\n",1);
        Check(c.Tick(100).Count==0,"historical events not replayed on connect");
        Check(Wire.Get(Wire.Parse(Wire.Read(Path.Combine(folder,"client.txt"))),"session")=="s1","client lease uses game session");
        Check(c.Queue("spike",100)==null && c.HasPending,"valid request queued without claiming success");
        Dictionary<string,string> cmd=Wire.Parse(Wire.Read(Path.Combine(folder,"command.txt")));
        Check(Wire.Get(cmd,"target")=="enemy" && Wire.Get(cmd,"action")=="spike","command pins crosshair entity");
        Check(c.Queue("erase",100).Contains("pending"),"second pending request blocked");
        Wire.Publish(Path.Combine(folder,"result.txt"),Wire.Pack(Wire.Get(cmd,"id"),"session","s1","ok","0","message","Target changed."));
        List<string> lines=c.Tick(101);
        Check(lines.Count==1 && lines[0].Contains("Hack refused") && !c.HasPending,"game rejection reported accurately");
        PublishSnapshot(folder,"s1",102,"eligible=0\n",1); c.Tick(102);
        Check(c.Queue("erase",102).Contains("Aim"),"ineligible target refused locally");
        Check(c.Queue("assist_off",102)==null,"stand down requires no target");
        cmd=Wire.Parse(Wire.Read(Path.Combine(folder,"command.txt")));
        Wire.Publish(Path.Combine(folder,"result.txt"),Wire.Pack(Wire.Get(cmd,"id"),"session","s1","ok","1","message","Standing down."));
        Check(c.Tick(103)[0]=="Standing down.","game success acknowledged");
        PublishSnapshot(folder,"s1",103,"eligible=0\ntarget=\n",1); c.Tick(103);
        Check(c.Queue("chaos_on",103)==null,"chaos toggle requires no crosshair target");
        cmd=Wire.Parse(Wire.Read(Path.Combine(folder,"command.txt")));
        Wire.Publish(Path.Combine(folder,"result.txt"),Wire.Pack(Wire.Get(cmd,"id"),"session","s1","ok","1","message","Chaos on."));
        Check(c.Tick(103)[0]=="Chaos on.","chaos toggle acknowledgement");
        PublishSnapshot(folder,"s1",104,"event_1=2|kill|death\nevent_2=3|low_health|danger\n",3);
        lines=c.Tick(104); Check(lines.Count==1 && lines[0].Contains("critical"),"higher priority health reaction wins");
        Check(c.Tick(105).Count==0,"same event is not spoken twice");
        PublishSnapshot(folder,"s1",106,"event_1=4|vehicle_enter|vehicle\n",4);
        Check(c.Tick(106).Count==0,"reaction interval prevents chatter");
        PublishSnapshot(folder,"s1",113,"event_1=4|vehicle_enter|vehicle\n",4);
        Check(c.Tick(113).Count==0,"routine vehicle chatter is suppressed entirely");
        PublishSnapshot(folder,"s1",134,"event_1=5|kill|death\nevent_2=6|hack|upload\nevent_3=7|combat_start|combat\nevent_4=8|objective|tracker\n",8);
        Check(c.Tick(134).Count==0,"routine kills uploads combat and objectives never chatter");
        PublishSnapshot(folder,"s1",135,"event_1=9|wanted|increased\n",9);
        Check(c.Tick(135).Count==1 && c.Reports.Count==1 && !c.Reports[0].Manual,"important event carries factual brain-report metadata");
        c.Reactions=false;
        PublishSnapshot(folder,"s1",114,"event_1=5|blackwall|breach\n",5);
        Check(c.Tick(114).Count==0,"quiet reactions remain silent"); c.Reactions=true;
        Check(c.Tick(115).Count==0,"muted events cannot replay on resume");
        PublishSnapshot(folder,"s1",116,"",5); c.Tick(116); Check(c.Queue("erase",116)==null,"second request can be queued");
        PublishSnapshot(folder,"s2",117,"",0);
        lines=c.Tick(117); Check(lines.Count==1 && lines[0].Contains("session changed"),"save/session change cancels pending request");
        c.Queue("spike",117); lines=c.Tick(126);
        Check(lines.Count==1 && lines[0].Contains("Outcome unknown") && !c.HasPending,"timeout reports unknown outcome without replay");
        Check(c.Queue("spike",126).Contains("offline"),"stale session cannot accept request");
        Check(!c.Report(126).Contains("Health 80"),"stale health is not reported as live");
    }
    sealed class ReportHost : CapriDesktop.ICapriHost
    {
        public object capri;
        public readonly List<string> Lines=new List<string>();
        public string Folder { get { return Path.GetTempPath(); } }
        public void Say(string line) { lock(Lines) Lines.Add(line); }
        public void Log(string line) { }
        public System.Drawing.Bitmap Art(string name) { return null; }
        public void PlayIntro() { } public void Sound(string name) { }
        public int Count { get { lock(Lines) return Lines.Count; } }
    }
    sealed class FakeReportBrain
    {
        public string Model="selected model A";
        public static string Persona { get { return "Configured personality"; } }
        internal string Aside(string system,string prompt,int limit,bool job)
        {
            return Model+"|"+system+"|"+prompt+"|"+limit+"|"+job;
        }
    }
    sealed class FakeReportOwner { public FakeReportBrain brain=new FakeReportBrain(); }
    sealed class FakeSpeechOwner
    {
        public Action Posted;
        public bool Busy;
        public string Spoken;
        public int Posts;
        private bool LineBusy { get { return Busy; } }
        private void Post(Action action) { Interlocked.Increment(ref Posts); Posted=action; }
        private void Remark(string shown,string line,bool bubble,byte[] prepared,bool ready) { Spoken=line; }
    }
    static void ReporterTests()
    {
        FakeReportOwner fakeOwner=new FakeReportOwner();
        Func<string,string,string> bound=BrainReporter.Bind(new ReportHost { capri=fakeOwner });
        string boundReply=bound("Grounding rules","Only game facts");
        Check(boundReply.Contains("selected model A|Configured personality") && boundReply.EndsWith("|100|False"),"internal adapter uses selected brain persona and bounded independent Aside call");
        fakeOwner.brain=new FakeReportBrain { Model="selected model B" };
        Check(bound("rules","facts").StartsWith("selected model B"),"brain is resolved again after model/brain replacement");
        Check(BrainReporter.Validate("He's dead.","Kill request queued.")==null,"brain cannot upgrade a queued kill to a confirmed death");
        Check(BrainReporter.Validate("Vehicle destroyed.","Vehicle explosion requested.")==null,"brain cannot invent vehicle destruction");
        Check(BrainReporter.Validate("Sending the upload.","Optics Blackout uploaded.")!=null,"honest request wording accepted");
        Check(BrainReporter.Validate("Target down.","Target death confirmed.")!=null,"confirmed death can be worded naturally");
        Check(BrainReporter.Validate("use_computer click the target","Scan complete")==null,"brain report cannot issue computer actions");
        Check(BrainReporter.Validate("It's all taken care of.","Vehicle explosion requested.")==null,"uncertain action must retain an explicit request qualifier");
        ReportHost host=new ReportHost(); int calls=0; bool valid=true,grounded=false;
        BrainReporter reporter=new BrainReporter(host,delegate(GameReport r) { return valid; },delegate(string system,string prompt) {
            Interlocked.Increment(ref calls); grounded=system.Contains("NOT confirmed") && prompt.Contains("GAME FACT");
            return "Sending the upload.";
        });
        reporter.Start();
        reporter.Enqueue(new GameReport { Fact="Optics Blackout uploaded.",At=Wire.Now,Manual=true,Context="health_percent=80" });
        DateTime until=DateTime.UtcNow.AddSeconds(2); while(host.Count==0 && DateTime.UtcNow<until) Thread.Sleep(20);
        Check(host.Count==1 && calls==1,"report goes through supplied brain and speaks generated wording");
        Check(grounded,"brain receives grounding instructions and facts");
        reporter.Enqueue(new GameReport { Fact="Optics Blackout uploaded.",At=Wire.Now,Manual=true });
        Thread.Sleep(150); Check(host.Count==1 && calls==1,"burst duplicate acknowledgement does not call brain or speak again");
        valid=false;
        reporter.Enqueue(new GameReport { Fact="New important event",At=Wire.Now });
        Thread.Sleep(150); Check(calls==1,"stale session is discarded before provider call");
        reporter.Enqueue(new GameReport { Fact="Hack refused: target protected.",At=Wire.Now,Failure=true });
        Check(host.Count==2 && calls==1,"refusals remain literal and do not require brain");
        reporter.Stop();
        ReportHost lateHost=new ReportHost();
        BrainReporter late=new BrainReporter(lateHost,delegate(GameReport r) { return true; },delegate(string s,string p) { Thread.Sleep(3300); return "Late provider reply."; });
        late.Start(); late.Enqueue(new GameReport { Fact="Vehicle explosion requested.",At=Wire.Now,Manual=true });
        until=DateTime.UtcNow.AddSeconds(4); while(lateHost.Count==0 && DateTime.UtcNow<until) Thread.Sleep(20);
        Check(lateHost.Count==1 && lateHost.Lines[0]=="Vehicle explosion requested.","slow brain falls back to factual manual acknowledgement");
        Thread.Sleep(500); Check(lateHost.Count==1,"late provider result is never spoken a second time"); late.Stop();
        FakeSpeechOwner speaker=new FakeSpeechOwner(); ReportHost speakingHost=new ReportHost { capri=speaker };
        BrainReporter guarded=new BrainReporter(speakingHost,delegate(GameReport r) { return true; },delegate(string s,string p) { return "Sending the upload."; });
        guarded.Start(); guarded.Enqueue(new GameReport { Fact="Optics Blackout uploaded.",At=Wire.Now,Manual=true });
        until=DateTime.UtcNow.AddSeconds(2); while(speaker.Posted==null && DateTime.UtcNow<until) Thread.Sleep(20);
        Check(speaker.Posted!=null,"report is delivered through a guarded window callback");
        speaker.Busy=true; speaker.Posted();
        Check(speaker.Spoken==null && speakingHost.Count==0,"busy voice drops report instead of adding stale host speech queue");
        guarded.Stop();
        speaker.Busy=false; speaker.Posted(); Check(speaker.Spoken==null,"pending window callback cannot speak after mod unload");
        FakeSpeechOwner coalesced=new FakeSpeechOwner(); ReportHost coalescedHost=new ReportHost { capri=coalesced };
        int compositions=0;
        BrainReporter coalescer=new BrainReporter(coalescedHost,delegate(GameReport r) { return true; },delegate(string s,string p) { Interlocked.Increment(ref compositions); return p.Contains("Second")?"Second state.":"First state."; });
        coalescer.Start(); coalescer.Enqueue(new GameReport { Fact="First state.",At=Wire.Now,Manual=true });
        until=DateTime.UtcNow.AddSeconds(2); while(coalesced.Posts==0 && DateTime.UtcNow<until) Thread.Sleep(10);
        coalescer.Enqueue(new GameReport { Fact="Second state.",At=Wire.Now,Manual=true });
        until=DateTime.UtcNow.AddSeconds(2); while(compositions<2 && DateTime.UtcNow<until) Thread.Sleep(10);
        Thread.Sleep(100); Check(coalesced.Posts==1,"blocked UI receives only one outstanding optional-report callback");
        coalesced.Posted(); Check(coalesced.Spoken=="Second state.","coalesced UI callback speaks the latest report instead of a stale backlog"); coalescer.Stop();
        using(ManualResetEvent entered=new ManualResetEvent(false)) using(ManualResetEvent release=new ManualResetEvent(false)) using(ManualResetEvent finished=new ManualResetEvent(false)) {
            int replacementCalls=0;
            BrainReporter hung=new BrainReporter(new ReportHost(),delegate(GameReport r) { return true; },delegate(string s,string p) { entered.Set(); release.WaitOne(); finished.Set(); return "Old reply."; });
            hung.Start(); hung.Enqueue(new GameReport { Fact="A slow call.",At=Wire.Now,Manual=true });
            Check(entered.WaitOne(2000),"fixture provider is running during unload");
            Stopwatch stopWatch=Stopwatch.StartNew(); hung.Stop(); Check(stopWatch.ElapsedMilliseconds<900,"unload stops report worker promptly without waiting for provider completion");
            BrainReporter replacement=new BrainReporter(new ReportHost(),delegate(GameReport r) { return true; },delegate(string s,string p) { Interlocked.Increment(ref replacementCalls); return "New reply."; });
            try { replacement.Start(); replacement.Enqueue(new GameReport { Fact="Replacement report.",At=Wire.Now,Manual=true }); Thread.Sleep(200);
                Check(replacementCalls==0,"replacement mod cannot add a second outstanding provider call after reload"); }
            finally { replacement.Stop(); release.Set(); Check(finished.WaitOne(2000),"provider fixture releases its one shared slot"); }
        }
    }
    static bool WaitFor(BridgeClient client,string expected)
    {
        DateTime deadline=DateTime.UtcNow.AddSeconds(3);
        while(DateTime.UtcNow<deadline)
        {
            foreach(string line in client.Tick(Wire.Now)) if(line.Contains(expected)) return true;
            Thread.Sleep(30);
        }
        return false;
    }
    static void StopContentionTest()
    {
        NightCityMod mod=new NightCityMod();
        var flags=System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.NonPublic;
        mod.GetType().GetField("host",flags).SetValue(mod,new ReportHost());
        object gate=mod.GetType().GetField("gate",flags).GetValue(mod);
        using(ManualResetEvent entered=new ManualResetEvent(false)) using(ManualResetEvent release=new ManualResetEvent(false)) using(ManualResetEvent stopped=new ManualResetEvent(false)) {
            Thread blocked=new Thread(delegate() { lock(gate) { entered.Set(); release.WaitOne(); } }) { IsBackground=true };
            mod.GetType().GetField("worker",flags).SetValue(mod,blocked); blocked.Start();
            Check(entered.WaitOne(2000),"fixture bridge worker holds the polling lock");
            Thread unload=new Thread(delegate() { mod.Stop(); stopped.Set(); }) { IsBackground=true }; unload.Start();
            bool prompt=false;
            try { prompt=stopped.WaitOne(1200); }
            finally { release.Set(); blocked.Join(2000); unload.Join(2000); }
            Check(prompt,"mod unload cannot deadlock on a blocked polling lock");
            Check(!mod.Heard("night city help"),"stopped bridge rejects late commands");
        }
    }
    static void CrossRuntime(string root,string lua,string project,string kind,string phrase,string expected)
    {
        string folder=Path.Combine(root,"cross-runtime-"+kind+"-"+Guid.NewGuid().ToString("N")); Directory.CreateDirectory(folder);
        ProcessStartInfo start=new ProcessStartInfo(lua,"\""+Path.Combine(project,"tests","game-tests.lua")+"\" \""+Path.Combine(project,"CapriNightCityBridge")+"\" peer_"+kind);
        start.WorkingDirectory=folder; start.UseShellExecute=false; start.CreateNoWindow=true; start.RedirectStandardOutput=true; start.RedirectStandardError=true;
        using(Process peer=Process.Start(start))
        {
            try
            {
                BridgeClient client=new BridgeClient(folder); DateTime deadline=DateTime.UtcNow.AddSeconds(3);
                while(!client.Connected(Wire.Now) && DateTime.UtcNow<deadline) { client.Tick(Wire.Now); Thread.Sleep(20); }
                Check(client.Connected(Wire.Now),kind+": C# receives live Lua snapshot through real files");
                Check(Wire.Get(client.Snapshot,"target_kind")==kind,kind+": target type reaches Capri");
                Check(client.Queue(BridgeClient.Keyword(phrase),Wire.Now)==null,kind+": natural command is queued");
                Check(WaitFor(client,expected),kind+": native-adapter mock acknowledgement reaches Capri");
                Check(client.Queue("chaos_on",Wire.Now)==null && WaitFor(client,"Chaos mode on"),kind+": chaos can be enabled through real protocol");
                Check(client.Queue("assist_off",Wire.Now)==null && WaitFor(client,"All autonomous attacks standing down"),kind+": stand down stops chaos through real protocol");
                File.WriteAllText(Path.Combine(folder,"peer-stop.txt"),"stop");
                if(!peer.WaitForExit(7000)) throw new Exception("Lua peer did not finish.");
                Check(peer.ExitCode==0,kind+": cross-runtime peer exits cleanly");
            }
            finally { if(!peer.HasExited) peer.Kill(); }
        }
    }
    [STAThread]
    public static int Main(string[] args)
    {
        try
        {
            PublicSetupTest(args[0]);
            MainTests(args[0]);
            ReporterTests();
            StopContentionTest();
            CrossRuntime(args[0],args[1],args[2],"npc","blind the guy in front of me","Optics Blackout uploaded");
            CrossRuntime(args[0],args[1],args[2],"npc","use ghost veil on the guy in front of me","Ghost Veil uploaded");
            CrossRuntime(args[0],args[1],args[2],"vehicle","stop the car","Vehicle brake hack engaged");
            CrossRuntime(args[0],args[1],args[2],"device","hack the camera","Device action queued");
            CrossRuntime(args[0],args[1],args[2],"access_point","hack the access point","Access point network breached");
            Console.WriteLine("PASS "+count+" Capri/protocol checks. Real game and voice not tested."); return 0;
        }
        catch(Exception e) { Console.Error.WriteLine(e); return 1; }
    }
}
