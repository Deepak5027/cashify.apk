import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import prisma from './prismaClient.js';

const backendUrl = process.env.BACKEND_URL || 'http://localhost:4000';

passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: `${backendUrl}/auth/google/callback`
}, async (accessToken, refreshToken, profile, done) => {
  try {
    const email = profile.emails && profile.emails[0] && profile.emails[0].value;
    const image = profile.photos && profile.photos[0] && profile.photos[0].value;
    let user = null;
    if (email) {
      user = await prisma.user.findUnique({ where: { email } });
    }
    if (!user) {
      user = await prisma.user.create({
        data: {
          name: profile.displayName,
          email,
          image,
          lastLogin: new Date(),
          lastLoginDevice: 'Google OAuth Web',
        }
      });
    } else {
      const updateData = { lastLogin: new Date(), lastLoginDevice: 'Google OAuth Web' };
      if (image && !user.image) {
        updateData.image = image;
      }
      user = await prisma.user.update({ where: { id: user.id }, data: updateData });
    }
    return done(null, user);
  } catch (err) {
    return done(err);
  }
}));

passport.serializeUser((user, done) => done(null, user.id));
passport.deserializeUser(async (id, done) => {
  try {
    const user = await prisma.user.findUnique({ where: { id } });
    done(null, user);
  } catch (err) {
    done(err);
  }
});

export default passport;
