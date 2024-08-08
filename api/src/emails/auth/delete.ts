export const deleteAccountMail = (name: string) => `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thank You for Using Voice Learn</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f6f6f6;
            margin: 0;
            padding: 0;
        }
        .container {
            width: 100%;
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #333333;
            font-size: 24px;
            margin-bottom: 20px;
        }
        p {
            color: #555555;
            font-size: 16px;
            line-height: 1.5;
            margin-bottom: 20px;
        }
        .footer {
            font-size: 14px;
            color: #999999;
            text-align: center;
            margin-top: 40px;
        }
        .btn {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Thank You for Using Voice Learn!</h1>
        <p>Dear ${name},</p>
        <p>We're sorry to see you go, but we wanted to take a moment to thank you for using Voice Learn. Your time and trust in our app have meant a lot to us.</p>
        <p>If there's anything we could have done better, we would love to hear from you. Your feedback helps us improve and serve our users better in the future.</p>
        <p>If you have a moment, please <a href="https://forms.gle/S1D6KyWbQS6CyaU77" class="btn">share your feedback</a> with us.</p>
        <p>Thank you once again for being a part of our community. We hope to see you again!</p>
        <p>Best regards,<br>Voice Learn Team</p>
    </div>
    <div class="footer">
        &copy; ${new Date().getFullYear()} Voice Learn. All rights reserved.
    </div>
</body>
</html>
`;
