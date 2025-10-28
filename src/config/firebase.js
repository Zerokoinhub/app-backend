const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = {
  "type": "service_account",
  "project_id": "zerokoin-705c5",
  "private_key_id": "c922007a558567e203c0a82bfdbe8ba631c37d90",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCSZgityBWVX0zX\neRyUFobqI1HJRoR57g89u50ZQamaa1rh/UVyabQrs7HKmAYFsBWU3rVNbmAm2cF9\n0YGldBU1bdn3w2VUmNWUHWAmzVxVdkU43XPiu7MKnZACVE9mtHzCJftp6b9WvRSd\nUkaSz6FhTxUbGPgT0MrAYsPBOJHSr1FBKgckXoro5eNn2o1nwMRdnAc8a7YfHdRT\n3xi36HP+d/VIlYOWN1JuLYh2ByNVYQ0rnDeidVOE194tF8GE9dMPBPRjJZ5K27j2\noVBSgssVLyrxxEllB2bctzqZs+v9En0uFPUmLrp6D0+2ZGDj5mvyfwgM7APRe3J7\nwoJD2n/FAgMBAAECggEAH4aG5GtTkIbE7JqpR4+BTo68CDieAwa7c/sAhcWQ0Q7A\ns60fZRezo3yO8vZhR5zHTPdXefzkikE2rFIvFbLFdWu6NiM24SyHQ52+zKRI96Ng\nHTJ9B8yNLeJHtmSy84Y23nUg6ooaOMK/W3Bx/5/kG+kUfbEXDOdXne22w1db+Y8R\nbW/WVT/dqGGYx2stlow1ritopXQzkC4euCybh1gDNNPPlpP5FqJkfMleeWxGjQ3e\nqA1vsH1I86k7T+GCTmFAKE9Gj4VcfMe1pd8OA2lP5LGWzQkwbhcBsGK0I7aKRyJK\nFMs+fLuhm50jaPcgB1d20rk6uXzJug68a1bqeMKDGQKBgQDGAysTvVfAg3rNvI37\nMRIbMFrTNn5v1aJTfSG3w121pXvPlcCnGLR1pBeCjTl7neDkhARuLehFuXUgv5Jc\nQOPO9FZq0RLZ35TBKh7qxz6apaMFEgBJAJQF9/cqIjS0OzOlDIRwyNGLIqNufeMs\nrHvkyYqkBF14UkkH02l+7K/G2QKBgQC9RWtVrm33SGBt4up9dTDIBC4xEsuOpe1+\nl973EOleNLk4/yFTa7iZUNkQjnx0HgAAyQEiCXWrHtRFlhpIP8GzwO/sjHJohWmw\nQl4u2DaaBG7rqpJEkKrMjwiMwH8hveDohMzuNbe7VGDozkT0DFNY2cPhvduMW1S/\nDQQ8hJfkzQKBgGBuMpBOaWnLngaLiOmHoDW1esXZiAGWnJLkIYOIlR5dFMqnN0co\n9NlFrF1bwV6+KEOhNzchDDjIdI4aPYDH6SlkPKGQaAnKpHrdtGjJ12cgux9BAPqM\nWYn+lFPkjJ4pJqF+UxFJ+yIzIDwy+mtLJJrqu6XcqlhqWj6BaqLxSTkhAoGAHUx+\ntg+/ZBUnIDuNMwiOGZhUEjKnohhbcEpQMIzEo1mkBoev//rf45PZVi/IYi02sOhs\nrXkrZubp0y/ON7ru4EWQnlyLZVSprKhJbhT4NtVS2lZYOBbw6aOGnks6It4Cz9um\n4YUdQPlp2v/7OpAh4tIq+Wnrb4m/z6dTLY8U+E0CgYEAu14VvZFJY5i9ZZTB7gEn\nPT8XPFQ41d2COQkDU1Fb/KPgpyC2sFkE7pCalzyw/PnyH5L0lVD0KGrZq6haD7WJ\nIIhGPcBL/H8hqaq99/Kq7Qx7fxx0ndEPs33m/h7esfJMQkK2rXaLBvL6ZvA8ywfi\nB9/oHLuXmA38tJYMzfYBI0A=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@zerokoin-705c5.iam.gserviceaccount.com",
  "client_id": "108588023842407313656",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40zerokoin-705c5.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};

// Initialize Firebase Admin SDK
try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase Admin initialized successfully');
} catch (error) {
  console.error('Firebase initialization error:', error);
}

module.exports = { admin }; 
