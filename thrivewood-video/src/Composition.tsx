import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  Easing,
  Img,
  staticFile,
  Sequence,
  spring,
} from "remotion";

const forestGradient = "linear-gradient(135deg, #1a472a 0%, #2d5a27 25%, #4a7c23 50%, #6b8e23 75%, #8fbc8f 100%)";
const warmGradient = "linear-gradient(180deg, #0d1f0d 0%, #1a3a1a 50%, #2d4a2d 100%)";

export const MyComposition = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <AbsoluteFill style={{ background: warmGradient }}>
      <Sequence name="Background" from={0}>
        <Background />
      </Sequence>
      
      <Sequence name="Scene 1 - Hero" from={0} durationInFrames={Math.round(3.5 * fps)}>
        <HeroScene />
      </Sequence>

      <Sequence name="Scene 2 - Forest" from={Math.round(3.5 * fps)} durationInFrames={Math.round(4 * fps)}>
        <FeatureScene
          title="Dein virtueller Wald"
          subtitle="Jede Gewohnheit pflanzt einen Baum"
          image="01-hero.jpeg"
        />
      </Sequence>

      <Sequence name="Scene 3 - Habits" from={Math.round(7.5 * fps)} durationInFrames={Math.round(4 * fps)}>
        <FeatureScene
          title="Gewohnheiten tracken"
          subtitle="Streaks, Punkte & Fortschritt"
          image="02-device-bottom.jpeg"
        />
      </Sequence>

      <Sequence name="Scene 4 - Workout" from={Math.round(11.5 * fps)} durationInFrames={Math.round(4 * fps)}>
        <FeatureScene
          title="Workout Tracker"
          subtitle="Muskelranking & PRs"
          image="03-two-devices.jpeg"
        />
      </Sequence>

      <Sequence name="Scene 5 - Analytics" from={Math.round(15.5 * fps)} durationInFrames={Math.round(4 * fps)}>
        <FeatureScene
          title="Detaillierte Analytics"
          subtitle="Dein Fortschritt auf einen Blick"
          image="06-hero.jpeg"
        />
      </Sequence>

      <Sequence name="Scene 6 - Features List" from={Math.round(19.5 * fps)} durationInFrames={Math.round(4 * fps)}>
        <FeaturesListScene />
      </Sequence>

      <Sequence name="Scene 7 - CTA" from={Math.round(23.5 * fps)} durationInFrames={Math.round(4.5 * fps)}>
        <CTAScene />
      </Sequence>
    </AbsoluteFill>
  );
};

const Background = () => {
  return (
    <AbsoluteFill>
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(circle at 50% 30%, rgba(107, 142, 35, 0.15) 0%, transparent 60%)",
        }}
      />
      <FloatingParticles />
    </AbsoluteFill>
  );
};

const FloatingParticles = () => {
  const frame = useCurrentFrame();
  const { height } = useVideoConfig();
  
  return (
    <AbsoluteFill style={{ opacity: 0.4 }}>
      {[...Array(20)].map((_, i) => {
        const startX = (i * 47) % 100;
        const startY = (i * 31) % 100;
        const duration = 200 + (i % 5) * 50;
        const progress = (frame % duration) / duration;
        const y = interpolate(progress, [0, 1], [height + 50, -50]);
        const x = startX + Math.sin(progress * Math.PI * 2 + i) * 5;
        
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: `${x}%`,
              top: y,
              width: 4 + (i % 3) * 2,
              height: 4 + (i % 3) * 2,
              borderRadius: "50%",
              background: i % 2 === 0 ? "#4a7c23" : "#8fbc8f",
              opacity: 0.3 + (i % 5) * 0.1,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

const HeroScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleOpacity = spring({
    frame,
    fps,
    config: { damping: 100, stiffness: 200 },
  });

  const subtitleProgress = spring({
    frame: frame - 15,
    fps,
    config: { damping: 100, stiffness: 200 },
  });

  const scale = interpolate(
    frame,
    [0, 20],
    [0.8, 1],
    { extrapolateRight: "clamp", easing: Easing.out(Easing.cubic) }
  );

  const glowOpacity = interpolate(
    frame,
    [30, 60],
    [0, 0.5],
    { extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill
      style={{
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        gap: 20,
      }}
    >
      <div
        style={{
          position: "absolute",
          width: 300,
          height: 300,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(107, 142, 35, 0.4) 0%, transparent 70%)",
          opacity: glowOpacity,
          filter: "blur(40px)",
        }}
      />
      
      <div
        style={{
          transform: `scale(${scale})`,
          opacity: titleOpacity,
        }}
      >
        <h1
          style={{
            fontFamily: "SF Pro Display, -apple-system, sans-serif",
            fontSize: 72,
            fontWeight: 700,
            background: forestGradient,
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            textShadow: "0 4px 30px rgba(74, 124, 35, 0.3)",
            letterSpacing: "-2px",
          }}
        >
          ThriveWood
        </h1>
      </div>
      
      <div
        style={{
          opacity: Math.max(0, subtitleProgress),
          transform: `translateY(${interpolate(subtitleProgress, [0, 1], [20, 0])}px)`,
        }}
      >
        <p
          style={{
            fontFamily: "SF Pro Text, -apple-system, sans-serif",
            fontSize: 28,
            color: "#a8c99a",
            fontWeight: 500,
            letterSpacing: "0.5px",
          }}
        >
          Grow your habits. Grow your forest.
        </p>
      </div>

      <div
        style={{
          position: "absolute",
          bottom: 80,
          opacity: interpolate(frame, [60, 90], [0, 1], { extrapolateRight: "clamp" }),
        }}
      >
        <div
          style={{
            width: 50,
            height: 50,
            borderRadius: "50%",
            border: "2px solid rgba(168, 201, 154, 0.5)",
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            animation: "bounce 1s infinite",
          }}
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#a8c99a" strokeWidth="2">
            <path d="M12 5v14M5 12l7 7 7-7" />
          </svg>
        </div>
      </div>
    </AbsoluteFill>
  );
};

const FeatureScene = ({
  title,
  subtitle,
  image,
}: {
  title: string;
  subtitle: string;
  image: string;
}) => {
  const frame = useCurrentFrame();
  const { fps, width } = useVideoConfig();

  const titleOpacity = spring({
    frame,
    fps,
    config: { damping: 100, stiffness: 200 },
  });

  const imageOpacity = spring({
    frame: frame - 10,
    fps,
    config: { damping: 100, stiffness: 200 },
  });

  const imageScale = spring({
    frame: frame - 10,
    fps,
    config: { damping: 15, stiffness: 100 },
  });

  return (
    <AbsoluteFill
      style={{
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        gap: 30,
        padding: 40,
      }}
    >
      <div
        style={{
          opacity: titleOpacity,
          transform: `translateY(${interpolate(titleOpacity, [0, 1], [-30, 0])}px)`,
          textAlign: "center",
          position: "absolute",
          top: 60,
        }}
      >
        <h2
          style={{
            fontFamily: "SF Pro Display, -apple-system, sans-serif",
            fontSize: 42,
            fontWeight: 700,
            color: "#ffffff",
            marginBottom: 8,
          }}
        >
          {title}
        </h2>
        <p
          style={{
            fontFamily: "SF Pro Text, -apple-system, sans-serif",
            fontSize: 22,
            color: "#a8c99a",
          }}
        >
          {subtitle}
        </p>
      </div>

      <div
        style={{
          opacity: imageOpacity,
          transform: `scale(${Math.min(imageScale, 1.05)})`,
          marginTop: 180,
          borderRadius: 24,
          overflow: "hidden",
          boxShadow: "0 25px 80px rgba(0, 0, 0, 0.5), 0 0 60px rgba(74, 124, 35, 0.2)",
        }}
      >
        <Img
          src={staticFile(image)}
          style={{
            width: width * 0.85,
            borderRadius: 24,
          }}
        />
      </div>
    </AbsoluteFill>
  );
};

const FeaturesListScene = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const features = [
    { icon: "🌲", text: "Virtueller Wald" },
    { icon: "✅", text: "Gewohnheiten" },
    { icon: "💪", text: "Workout Tracker" },
    { icon: "🏆", text: "Muskelranking" },
    { icon: "📊", text: "Analytics" },
  ];

  return (
    <AbsoluteFill
      style={{
        justifyContent: "center",
        alignItems: "center",
        padding: 60,
      }}
    >
      <h2
        style={{
          fontFamily: "SF Pro Display, -apple-system, sans-serif",
          fontSize: 48,
          fontWeight: 700,
          color: "#ffffff",
          marginBottom: 60,
          opacity: spring({ frame, fps, config: { damping: 100 } }),
        }}
      >
        Alle Features
      </h2>

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: 24,
          width: "100%",
          maxWidth: 500,
        }}
      >
        {features.map((feature, i) => {
          const delay = i * 8;
          const progress = spring({
            frame: frame - delay,
            fps,
            config: { damping: 15, stiffness: 100 },
          });

          return (
            <div
              key={i}
              style={{
                opacity: Math.max(0, progress),
                transform: `translateX(${interpolate(progress, [0, 1], [-50, 0])}px)`,
                display: "flex",
                alignItems: "center",
                gap: 20,
                padding: "20px 28px",
                background: "rgba(255, 255, 255, 0.08)",
                borderRadius: 16,
                border: "1px solid rgba(168, 201, 154, 0.2)",
              }}
            >
              <span style={{ fontSize: 36 }}>{feature.icon}</span>
              <span
                style={{
                  fontFamily: "SF Pro Text, -apple-system, sans-serif",
                  fontSize: 26,
                  color: "#ffffff",
                  fontWeight: 500,
                }}
              >
                {feature.text}
              </span>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

const CTAScene = () => {
  const frame = useCurrentFrame();
  const { fps, width } = useVideoConfig();

  const logoScale = spring({
    frame,
    fps,
    config: { damping: 12, stiffness: 100 },
  });

  const ctaProgress = spring({
    frame: frame - 20,
    fps,
    config: { damping: 100, stiffness: 200 },
  });

  const pulseScale = 1 + Math.sin(frame * 0.1) * 0.02;

  return (
    <AbsoluteFill
      style={{
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        gap: 40,
      }}
    >
      <div
        style={{
          transform: `scale(${logoScale})`,
          textAlign: "center",
        }}
      >
        <h1
          style={{
            fontFamily: "SF Pro Display, -apple-system, sans-serif",
            fontSize: 64,
            fontWeight: 700,
            background: forestGradient,
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            marginBottom: 16,
          }}
        >
          ThriveWood
        </h1>
        <p
          style={{
            fontFamily: "SF Pro Text, -apple-system, sans-serif",
            fontSize: 24,
            color: "#a8c99a",
          }}
        >
          Jetzt kostenlos herunterladen
        </p>
      </div>

      <div
        style={{
          opacity: Math.max(0, ctaProgress),
          transform: `scale(${pulseScale})`,
          marginTop: 40,
        }}
      >
        <div
          style={{
            padding: "24px 64px",
            background: "linear-gradient(135deg, #4a7c23 0%, #6b8e23 100%)",
            borderRadius: 50,
            boxShadow: "0 10px 40px rgba(74, 124, 35, 0.5)",
          }}
        >
          <span
            style={{
              fontFamily: "SF Pro Text, -apple-system, sans-serif",
              fontSize: 32,
              color: "#ffffff",
              fontWeight: 600,
            }}
          >
            App Store
          </span>
        </div>
      </div>

      <div
        style={{
          position: "absolute",
          bottom: 60,
          opacity: interpolate(frame, [60, 90], [0, 1], { extrapolateRight: "clamp" }),
        }}
      >
        <p
          style={{
            fontFamily: "SF Pro Text, -apple-system, sans-serif",
            fontSize: 18,
            color: "rgba(168, 201, 154, 0.7)",
          }}
        >
          iOS 17+
        </p>
      </div>
    </AbsoluteFill>
  );
};
