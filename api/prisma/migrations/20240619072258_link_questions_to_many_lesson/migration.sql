-- DropForeignKey
ALTER TABLE "Question" DROP CONSTRAINT "Question_lessonId_fkey";

-- CreateTable
CREATE TABLE "_LessonToQuestion" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "_LessonToQuestion_AB_unique" ON "_LessonToQuestion"("A", "B");

-- CreateIndex
CREATE INDEX "_LessonToQuestion_B_index" ON "_LessonToQuestion"("B");

-- AddForeignKey
ALTER TABLE "_LessonToQuestion" ADD CONSTRAINT "_LessonToQuestion_A_fkey" FOREIGN KEY ("A") REFERENCES "Lesson"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_LessonToQuestion" ADD CONSTRAINT "_LessonToQuestion_B_fkey" FOREIGN KEY ("B") REFERENCES "Question"("id") ON DELETE CASCADE ON UPDATE CASCADE;
