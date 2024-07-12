export const RESET_PASSWORD_EMAIL = (url: string) => `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Reset</title>
</head>
<body>
    <p>Hi there!</p>

    <p>It looks like you misplaced your password. No worries, it happens to the best of us! Just click the link below to set a new one and get back to conquering the digital world.</p>

    <p><a href="${url}">Reset Your Password</a></p>

    <p>But hurry, this link will self-destruct in 10 minutes! ⏳</p>

    <p>Cheers,<br>
    VoiceLearn Team</p>

    <p>P.S. We won't judge if you write this one down somewhere safe! 😉</p>
</body>
</html>

`;
