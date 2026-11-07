using System.Drawing;
namespace CapriDesktop {
public interface ICapriHost
    {
        string Folder { get; }
        void Say(string line);
        void Log(string line);
        Bitmap Art(string name);
        void PlayIntro();
        void Sound(string name);
    }

    public interface ICapriIntro
    {
        double Seconds { get; }
        void Begin(Bitmap desktop, Rectangle screen, Rectangle her);
        void Draw(Graphics graphics, Rectangle screen, Rectangle her, double at);
    }

    public interface ICapriMod
    {
        void Start(ICapriHost capri);
        bool Heard(string words);
        void Stop();
    }
}
